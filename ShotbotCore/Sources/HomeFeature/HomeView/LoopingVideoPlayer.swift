//
//  LoopingVideoPlayer.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/26/26.
//

import SwiftUI
import AVFoundation

/// Plays a video on a loop, without controls or a background, so a framed screen recording sits on the screen like an image.
struct LoopingVideoPlayer: UIViewRepresentable {
    /// The video to play.
    let url: URL

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        let player = AVQueuePlayer()

        context.coordinator.looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        view.backgroundColor = .clear
        player.play()

        return view
    }

    func updateUIView(_ view: PlayerView, context: Context) { }

    static func dismantleUIView(_ view: PlayerView, coordinator: Coordinator) {
        view.playerLayer.player?.pause()
        coordinator.looper?.disableLooping()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    /// Keeps the looper alive for as long as the view is.
    final class Coordinator {
        var looper: AVPlayerLooper?
    }

    /// A view backed by an `AVPlayerLayer`.
    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }

        var playerLayer: AVPlayerLayer {
            layer as! AVPlayerLayer
        }
    }
}
