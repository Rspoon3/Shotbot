//
//  VideoFramerTests.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/26/26.
//

import AVFoundation
import Testing
import UIKit
@testable import Models

struct VideoFramerTests {
    private let device = DeviceInfo.all().first { $0.name == "iPhone 17 Pro" }!

    @Test("Framing a video gives the frame's size and keeps the length")
    func framedVideoMatchesFrame() async throws {
        let source = try await makeVideo(size: device.inputSize, frames: 10)
        let output = FileManager.default.temporaryDirectory.appendingPathComponent("framed-\(UUID()).mp4")
        defer { try? FileManager.default.removeItem(at: output) }

        try await VideoFramer().frame(videoAt: source, in: device, to: output)

        let framedSize = try await VideoFramer.size(ofVideoAt: output)
        let frame = try #require(device.frameImage?.cgImage)
        #expect(abs(framedSize.width - CGFloat(frame.width)) <= 1)
        #expect(abs(framedSize.height - CGFloat(frame.height)) <= 1)

        let duration = try await AVURLAsset(url: output).load(.duration).seconds
        #expect(abs(duration - 1) < 0.2)
    }

    @Test("A partially open view makes room around the device for its shadow")
    func partiallyOpenVideoIsLarger() async throws {
        let duo = try #require(DeviceInfo.all().first {
            $0.name == "iPhone Duo" && $0.screenName == "Inner" && $0.orientation == .landscape
        }).withView("Partially Open")
        #expect(duo.isPartiallyOpen)

        let source = try await makeVideo(size: duo.inputSize, frames: 5)
        let output = FileManager.default.temporaryDirectory.appendingPathComponent("folded-\(UUID()).mp4")
        defer { try? FileManager.default.removeItem(at: output) }

        try await VideoFramer().frame(videoAt: source, in: duo, to: output)

        let size = try await VideoFramer.size(ofVideoAt: output)
        let frame = try #require(duo.frameImage?.cgImage)
        #expect(size.width > CGFloat(frame.width))
        #expect(size.height > CGFloat(frame.height))
    }

    @Test("A file without video is rejected")
    func rejectsNonVideo() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID()).mp4")
        try Data("nope".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        await #expect(throws: (any Error).self) {
            try await VideoFramer().frame(videoAt: url, in: device, to: url.appendingPathExtension("out"))
        }
    }

    // MARK: - Helpers

    /// Writes a solid red video at 10 frames per second.
    private func makeVideo(size: CGSize, frames: Int) async throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("source-\(UUID()).mp4")
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height)
        ])
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: Int(size.width),
            kCVPixelBufferHeightKey as String: Int(size.height)
        ])
        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        for index in 0..<frames {
            while !input.isReadyForMoreMediaData { try await Task.sleep(for: .milliseconds(5)) }

            var buffer: CVPixelBuffer?
            CVPixelBufferCreate(nil, Int(size.width), Int(size.height), kCVPixelFormatType_32BGRA, nil, &buffer)
            let pixels = try #require(buffer)
            CVPixelBufferLockBaseAddress(pixels, [])
            memset(CVPixelBufferGetBaseAddress(pixels), 0x80, CVPixelBufferGetDataSize(pixels))
            CVPixelBufferUnlockBaseAddress(pixels, [])

            adaptor.append(pixels, withPresentationTime: CMTime(value: CMTimeValue(index), timescale: 10))
        }

        input.markAsFinished()
        await writer.finishWriting()
        return url
    }
}
