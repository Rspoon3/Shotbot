//
//  VideoScene.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import AVFoundation
import CoreImage
import Models

/// Puts a screen recording in the same scene as screenshots: a device on a background, in the chosen shape.
enum VideoScene {
    /// Sets up a recording to play framed in a scene. Nothing is rendered until the video plays or is exported.
    /// - Parameters:
    ///   - sourceURL: The screen recording.
    ///   - device: The device to frame it in.
    ///   - recipe: The background, shape and shadow.
    static func prepare(sourceURL: URL, device: DeviceInfo, recipe: SceneRecipe) async throws -> PreparedVideo {
        let framer = VideoFramer()
        let store = LayerStore.shared

        // The device's outline never changes, so its shadow and the background are drawn once for every frame.
        let outline = try store.silhouette(of: device)
        let shadow = device.isPartiallyOpen ? nil : outline.shadow
        let deviceSize = try framer.deviceSize(in: device)

        let blank = DeviceRender(
            device: CIImage(color: .clear).cropped(to: CGRect(origin: .zero, size: deviceSize)),
            shadow: shadow
        )

        guard let layout = SceneComposer.compose([blank], recipe: recipe) else { throw LayerStore.LayerStoreError.bufferFailed }

        // Video needs whole, even pixel sizes.
        let size = CGSize(
            width: (layout.extent.width / 2).rounded(.up) * 2,
            height: (layout.extent.height / 2).rounded(.up) * 2
        )
        let background = try store.baked(
            BackgroundRenderer.image(recipe.background, size: size, blurSource: outline.device, blur: recipe.blur)
        )

        let canvas = VideoCanvas(size: size) { picture in
            SceneComposer.compose([DeviceRender(device: picture, shadow: shadow)], recipe: recipe, background: background)
                ?? background
        }

        return try await framer.prepare(videoAt: sourceURL, in: device, canvas: canvas)
    }
}
