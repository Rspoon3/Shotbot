//
//  VideoPreview.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import AVFoundation
import Models
import SwiftUI

/// Plays a recording framed in the scene, drawing every frame on the GPU as it plays.
///
/// The recording plays on its own, and each frame is pulled out, framed and drawn by the same code that exports the
/// video, so changing the background or shape shows up on the next frame without rendering a file.
struct VideoPreview: UIViewRepresentable {
    let video: PreparedVideo

    func makeUIView(context: Context) -> MetalImageView.CIMetalView {
        let view = MetalImageView.CIMetalView()
        context.coordinator.view = view
        return view
    }

    func updateUIView(_ view: MetalImageView.CIMetalView, context: Context) {
        context.coordinator.show(video)
    }

    static func dismantleUIView(_ view: MetalImageView.CIMetalView, coordinator: Coordinator) {
        coordinator.stop()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    /// Owns the player and draws its frames.
    final class Coordinator: NSObject {
        weak var view: MetalImageView.CIMetalView?

        private let player = AVPlayer()
        private var output: AVPlayerItemVideoOutput?
        private var link: CADisplayLink?
        private var video: PreparedVideo?
        private var sourceURL: URL?
        private var lastFrame: CIImage?
        private var endObserver: NSObjectProtocol?

        func show(_ video: PreparedVideo) {
            self.video = video

            guard video.asset.url != sourceURL else {
                // The same recording with new framing: draw the frame on screen again.
                draw()
                return
            }

            sourceURL = video.asset.url
            lastFrame = nil

            let output = AVPlayerItemVideoOutput(pixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferMetalCompatibilityKey as String: true
            ])
            let item = AVPlayerItem(asset: video.asset)
            item.add(output)
            self.output = output

            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }

            // Loop by starting over when the recording ends.
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak player] _ in
                player?.seek(to: .zero)
                player?.play()
            }

            player.replaceCurrentItem(with: item)
            player.play()

            if link == nil {
                let link = CADisplayLink(target: self, selector: #selector(tick))
                link.add(to: .main, forMode: .common)
                self.link = link
            }
        }

        func stop() {
            player.pause()
            link?.invalidate()
            link = nil

            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
        }

        @objc private func tick() {
            guard
                let output,
                let video,
                let item = player.currentItem
            else {
                return
            }

            let time = output.itemTime(forHostTime: CACurrentMediaTime())

            guard
                output.hasNewPixelBuffer(forItemTime: time),
                let buffer = output.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil)
            else {
                return
            }

            _ = item
            lastFrame = video.upright(CIImage(cvPixelBuffer: buffer))
            draw()
        }

        private func draw() {
            guard let video, let lastFrame else { return }

            view?.image = video.renderFrame(lastFrame)
        }
    }
}
