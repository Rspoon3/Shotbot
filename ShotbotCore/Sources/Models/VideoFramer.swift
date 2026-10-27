//
//  VideoFramer.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/26/26.
//

import AVFoundation
import CoreImage
import UIKit

/// Puts a screen recording inside a device frame.
///
/// Every video frame goes through the same steps as a screenshot: scale to the screen opening, clip to the
/// frame's screen mask, place at the frame's offset, then draw the frame on top.
public struct VideoFramer: Sendable {
    /// Why a video couldn't be framed.
    public enum VideoFramerError: LocalizedError, Equatable {
        case noVideoTrack
        case unsupportedView
        case missingFrame
        case exportFailed(String)

        public var errorDescription: String? {
            switch self {
            case .noVideoTrack: "The file doesn't contain a video."
            case .unsupportedView: "Partially open frames can't be used for videos yet."
            case .missingFrame: "The device frame couldn't be loaded."
            case .exportFailed(let reason): "The video couldn't be exported. \(reason)"
            }
        }
    }

    /// The color drawn around the device, outside its bezel.
    public var background: UIColor

    /// Creates a video framer.
    /// - Parameter background: The color behind the device. Defaults to white, like the Frames CLI.
    public init(background: UIColor = .white) {
        self.background = background
    }

    /// The pixel size of a video's first video track, after its rotation is applied.
    /// - Parameter url: The video file.
    public static func size(ofVideoAt url: URL) async throws -> CGSize {
        let asset = AVURLAsset(url: url)

        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoFramerError.noVideoTrack
        }

        let (naturalSize, transform) = try await track.load(.naturalSize, .preferredTransform)
        let size = naturalSize.applying(transform)

        return CGSize(width: abs(size.width), height: abs(size.height))
    }

    /// The video's first frame, upright and at full size, for showing the user what is being framed.
    ///
    /// Some videos, such as HDR screen recordings, can't be decoded into a still on every device. They get a plain
    /// image of the same size, which is all that device matching needs.
    /// - Parameter url: The video file.
    public static func posterImage(ofVideoAt url: URL) async throws -> UIImage {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.appliesPreferredTrackTransform = true

        if let (image, _) = try? await generator.image(at: .zero) {
            return UIImage(cgImage: image)
        }

        let size = try await size(ofVideoAt: url)
        return UIGraphicsImageRenderer(size: size, format: .singleScale).image { context in
            UIColor.secondarySystemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    /// Frames a video and writes it as an MP4, keeping the audio.
    /// - Parameters:
    ///   - sourceURL: The screen recording.
    ///   - device: The device whose frame to use, in the selected color and view.
    ///   - outputURL: Where to write the framed video. An existing file is replaced.
    public func frame(videoAt sourceURL: URL, in device: DeviceInfo, to outputURL: URL) async throws {
        guard !device.isPartiallyOpen else { throw VideoFramerError.unsupportedView }
        guard let frameImage = device.frameImage, let frameCG = frameImage.cgImage else {
            throw VideoFramerError.missingFrame
        }

        let asset = AVURLAsset(url: sourceURL)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoFramerError.noVideoTrack
        }

        let formatDescriptions = try await track.load(.formatDescriptions)

        // Encoders need even dimensions, so a frame with an odd side gets one transparent row or column of padding.
        let frameSize = CGSize(width: frameCG.width, height: frameCG.height)
        let renderSize = CGSize(
            width: Self.even(frameSize.width),
            height: Self.even(frameSize.height)
        )

        let layers = Layers(
            frame: CIImage(cgImage: frameCG),
            // The mask is gray, so its brightness is turned into the alpha the blend reads.
            mask: device.screenMask.map { CIImage(cgImage: $0).applyingFilter("CIMaskToAlpha") },
            background: CIImage(color: CIColor(color: background)).cropped(to: CGRect(origin: .zero, size: renderSize)),
            screenSize: device.screenSize,
            // Core Image's origin is the bottom-left, while the offset is measured from the top-left.
            screenOrigin: CGPoint(
                x: device.offSet.x,
                y: renderSize.height - device.offSet.y - device.screenSize.height
            )
        )

        let composition = try await AVMutableVideoComposition.videoComposition(with: asset) { request in
            request.finish(with: layers.render(request.sourceImage), context: nil)
        }
        composition.renderSize = renderSize
        Self.applyColorSpace(to: composition, matching: formatDescriptions)

        try? FileManager.default.removeItem(at: outputURL)

        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHEVCHighestQuality) else {
            throw VideoFramerError.exportFailed("No export session is available.")
        }

        session.videoComposition = composition
        session.outputURL = outputURL
        session.outputFileType = .mp4

        await session.export()

        if session.status != .completed {
            throw VideoFramerError.exportFailed(session.error?.localizedDescription ?? "")
        }
    }

    // MARK: - Private Helpers

    /// Exports with the source's color space, so HDR recordings stay HDR. The frame and background are SDR, and
    /// Core Image places them correctly on the HDR scale.
    private static func applyColorSpace(to composition: AVMutableVideoComposition, matching formatDescriptions: [CMFormatDescription]) {
        let transfer = formatDescriptions.first.flatMap {
            CMFormatDescriptionGetExtension($0, extensionKey: kCMFormatDescriptionExtension_TransferFunction) as? String
        }

        if transfer == kCMFormatDescriptionTransferFunction_SMPTE_ST_2084_PQ as String {
            composition.colorPrimaries = AVVideoColorPrimaries_ITU_R_2020
            composition.colorTransferFunction = AVVideoTransferFunction_SMPTE_ST_2084_PQ
            composition.colorYCbCrMatrix = AVVideoYCbCrMatrix_ITU_R_2020
        } else if transfer == kCMFormatDescriptionTransferFunction_ITU_R_2100_HLG as String {
            composition.colorPrimaries = AVVideoColorPrimaries_ITU_R_2020
            composition.colorTransferFunction = AVVideoTransferFunction_ITU_R_2100_HLG
            composition.colorYCbCrMatrix = AVVideoYCbCrMatrix_ITU_R_2020
        } else {
            composition.colorPrimaries = AVVideoColorPrimaries_ITU_R_709_2
            composition.colorTransferFunction = AVVideoTransferFunction_ITU_R_709_2
            composition.colorYCbCrMatrix = AVVideoYCbCrMatrix_ITU_R_709_2
        }
    }

    private static func even(_ value: CGFloat) -> CGFloat {
        let rounded = value.rounded(.up)
        return rounded.truncatingRemainder(dividingBy: 2) == 0 ? rounded : rounded + 1
    }

    /// The images every video frame is composed from.
    private struct Layers: @unchecked Sendable {
        let frame: CIImage
        let mask: CIImage?
        let background: CIImage
        let screenSize: CGSize
        let screenOrigin: CGPoint

        func render(_ source: CIImage) -> CIImage {
            let extent = source.extent

            var screen = source
                .transformed(by: CGAffineTransform(translationX: -extent.minX, y: -extent.minY))
                .transformed(by: CGAffineTransform(
                    scaleX: screenSize.width / extent.width,
                    y: screenSize.height / extent.height
                ))

            if let mask {
                screen = screen.applyingFilter("CIBlendWithAlphaMask", parameters: [
                    kCIInputBackgroundImageKey: CIImage.empty(),
                    kCIInputMaskImageKey: mask
                ])
            }

            screen = screen.transformed(by: CGAffineTransform(translationX: screenOrigin.x, y: screenOrigin.y))

            return frame
                .composited(over: screen.composited(over: background))
                .cropped(to: background.extent)
        }
    }
}
