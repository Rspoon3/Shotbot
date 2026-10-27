//
//  VideoExporter.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import AVFoundation
import CoreImage
import VideoToolbox

/// Writes a prepared video by reading its frames, framing each one on the GPU and handing it to the hardware HEVC
/// encoder.
///
/// This skips `AVAssetExportSession`, which pushes every frame through a general purpose composition pipeline. Here the
/// frames go straight from the decoder, through the same framing the preview draws, into the encoder, and the audio is
/// copied across without being decoded.
enum VideoExporter {
    /// Renders a prepared video to an MP4 file. An existing file is replaced.
    static func export(_ video: PreparedVideo, to outputURL: URL) async throws {
        try? FileManager.default.removeItem(at: outputURL)

        let job = try await ExportJob(video: video, outputURL: outputURL)

        do {
            try await job.run()
        } catch {
            try? FileManager.default.removeItem(at: outputURL)
            throw error
        }
    }

    /// One export in progress. Reading, framing and writing happen on queues of their own, so this is `@unchecked Sendable`
    /// and keeps its mutable state behind a lock.
    private final class ExportJob: @unchecked Sendable {
        private let video: PreparedVideo
        private let outputURL: URL
        private let reader: AVAssetReader
        private let writer: AVAssetWriter
        private let videoOutput: AVAssetReaderTrackOutput
        private let videoInput: AVAssetWriterInput
        private let adaptor: AVAssetWriterInputPixelBufferAdaptor
        private let audioOutput: AVAssetReaderTrackOutput?
        private let audioInput: AVAssetWriterInput?
        private let context = CIContext(options: [.cacheIntermediates: false])
        private let colorSpace: CGColorSpace
        private let sourceOptions: [CIImageOption: Any]
        private let lock = NSLock()
        private var cancelled = false

        // MARK: - Initializer

        init(video: PreparedVideo, outputURL: URL) async throws {
            self.video = video
            self.outputURL = outputURL

            let asset = video.asset

            guard let track = try await asset.loadTracks(withMediaType: .video).first else {
                throw VideoFramer.VideoFramerError.noVideoTrack
            }

            let audioTrack = try await asset.loadTracks(withMediaType: .audio).first
            let audioFormats = try await audioTrack?.load(.formatDescriptions)
            let frameRate = try await track.load(.nominalFrameRate)

            let isHDR = video.hdrColorSpace != nil
            let pixelFormat = isHDR ? kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange : kCVPixelFormatType_32BGRA
            let width = Int(video.renderSize.width)
            let height = Int(video.renderSize.height)

            reader = try AVAssetReader(asset: asset)
            videoOutput = AVAssetReaderTrackOutput(
                track: track,
                outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: pixelFormat]
            )
            videoOutput.alwaysCopiesSampleData = false
            reader.add(videoOutput)

            writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

            // Enough bits per pixel that text in a screen recording stays crisp, whatever the size or frame rate.
            let fps = frameRate > 0 ? Double(frameRate) : 60
            let bitRate = min(max(Double(width * height) * fps * 0.07, 6_000_000), 100_000_000)

            var compression: [String: Any] = [
                AVVideoAverageBitRateKey: Int(bitRate),
                AVVideoExpectedSourceFrameRateKey: Int(fps.rounded())
            ]
            var settings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.hevc,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height
            ]

            if let hdrColorSpace = video.hdrColorSpace {
                let isHLG = (hdrColorSpace.name as String?) == (CGColorSpace.itur_2100_HLG as String)

                compression[AVVideoProfileLevelKey] = kVTProfileLevel_HEVC_Main10_AutoLevel as String
                settings[AVVideoColorPropertiesKey] = [
                    AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_2020,
                    AVVideoTransferFunctionKey: isHLG ? AVVideoTransferFunction_ITU_R_2100_HLG : AVVideoTransferFunction_SMPTE_ST_2084_PQ,
                    AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_2020
                ]
                colorSpace = hdrColorSpace
                sourceOptions = [.colorSpace: hdrColorSpace]
            } else {
                settings[AVVideoColorPropertiesKey] = [
                    AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                    AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                    AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2
                ]
                colorSpace = CGColorSpace(name: CGColorSpace.itur_709) ?? CGColorSpace(name: CGColorSpace.sRGB)!
                sourceOptions = [:]
            }

            settings[AVVideoCompressionPropertiesKey] = compression

            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
            videoInput.expectsMediaDataInRealTime = false

            adaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: videoInput,
                sourcePixelBufferAttributes: [
                    kCVPixelBufferPixelFormatTypeKey as String: pixelFormat,
                    kCVPixelBufferWidthKey as String: width,
                    kCVPixelBufferHeightKey as String: height,
                    kCVPixelBufferIOSurfacePropertiesKey as String: [String: Any](),
                    kCVPixelBufferMetalCompatibilityKey as String: true
                ]
            )

            guard writer.canAdd(videoInput) else {
                throw VideoFramer.VideoFramerError.exportFailed("The video can't be written.")
            }

            writer.add(videoInput)

            // Audio is copied as it is, so it isn't decoded and encoded again.
            if let audioTrack {
                let output = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)
                let input = AVAssetWriterInput(mediaType: .audio, outputSettings: nil, sourceFormatHint: audioFormats?.first)

                guard reader.canAdd(output), writer.canAdd(input) else {
                    throw VideoFramer.VideoFramerError.exportFailed("The audio can't be copied.")
                }

                reader.add(output)
                writer.add(input)
                audioOutput = output
                audioInput = input
            } else {
                audioOutput = nil
                audioInput = nil
            }
        }

        // MARK: - Public Helpers

        /// Reads, frames and writes every frame, and the audio alongside.
        func run() async throws {
            guard reader.startReading() else {
                throw VideoFramer.VideoFramerError.exportFailed(reader.error?.localizedDescription ?? "")
            }

            guard writer.startWriting() else {
                throw VideoFramer.VideoFramerError.exportFailed(writer.error?.localizedDescription ?? "")
            }

            writer.startSession(atSourceTime: .zero)

            await withTaskCancellationHandler {
                await withTaskGroup(of: Void.self) { group in
                    group.addTask { await self.copyVideo() }

                    if self.audioInput != nil {
                        group.addTask { await self.copyAudio() }
                    }
                }
            } onCancel: {
                self.cancel()
            }

            if isCancelled {
                reader.cancelReading()
                writer.cancelWriting()
                throw CancellationError()
            }

            if reader.status == .failed {
                writer.cancelWriting()
                throw VideoFramer.VideoFramerError.exportFailed(reader.error?.localizedDescription ?? "")
            }

            await writer.finishWriting()

            guard writer.status == .completed else {
                throw VideoFramer.VideoFramerError.exportFailed(writer.error?.localizedDescription ?? "")
            }
        }

        // MARK: - Private Helpers

        private var isCancelled: Bool {
            lock.withLock { cancelled }
        }

        private func cancel() {
            lock.withLock { cancelled = true }
        }

        /// Frames and appends video frames for as long as the encoder wants more.
        private func copyVideo() async {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                videoInput.requestMediaDataWhenReady(on: DispatchQueue(label: "Shotbot.VideoExporter.video", qos: .userInitiated)) {
                    while self.videoInput.isReadyForMoreMediaData {
                        guard !self.isCancelled, let sample = self.videoOutput.copyNextSampleBuffer() else {
                            self.videoInput.markAsFinished()
                            continuation.resume()
                            return
                        }

                        if !self.append(sample) {
                            self.cancel()
                        }
                    }
                }
            }
        }

        private func copyAudio() async {
            guard let audioInput, let audioOutput else { return }

            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                audioInput.requestMediaDataWhenReady(on: DispatchQueue(label: "Shotbot.VideoExporter.audio", qos: .userInitiated)) {
                    while audioInput.isReadyForMoreMediaData {
                        guard !self.isCancelled, let sample = audioOutput.copyNextSampleBuffer() else {
                            audioInput.markAsFinished()
                            continuation.resume()
                            return
                        }

                        if !audioInput.append(sample) {
                            self.cancel()
                        }
                    }
                }
            }
        }

        /// Frames one decoded frame and gives it to the encoder. Returns `false` when it couldn't.
        private func append(_ sample: CMSampleBuffer) -> Bool {
            guard let frame = CMSampleBufferGetImageBuffer(sample) else { return true }
            guard let pool = adaptor.pixelBufferPool else { return false }

            var buffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)

            guard let buffer else { return false }

            let framed = video.renderFrame(video.upright(CIImage(cvPixelBuffer: frame, options: sourceOptions)))

            context.render(
                framed,
                to: buffer,
                bounds: CGRect(origin: .zero, size: video.renderSize),
                colorSpace: colorSpace
            )

            return adaptor.append(buffer, withPresentationTime: CMSampleBufferGetPresentationTimeStamp(sample))
        }
    }
}
