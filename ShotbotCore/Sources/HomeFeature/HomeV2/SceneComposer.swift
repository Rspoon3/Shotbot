//
//  SceneComposer.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import CoreImage

/// Puts finished device layers and a background together.
///
/// Nothing here draws pixels. The result is a Core Image description of the picture, so it is cheap to build every time
/// a slider moves, and the same description is drawn to the screen at preview size or to a file at full size.
enum SceneComposer {
    /// The picture of one or more devices side by side on a background.
    /// - Parameters:
    ///   - renders: The devices, left to right.
    ///   - recipe: The background, padding and shadow.
    ///   - background: A finished background to use instead of drawing one, for when the same scene is composed many times.
    /// - Returns: An image starting at the origin, or `nil` with no devices.
    static func compose(_ renders: [DeviceRender], recipe: SceneRecipe, background drawn: CIImage? = nil) -> CIImage? {
        guard !renders.isEmpty else { return nil }

        // Every device is scaled to the height of the tallest, so a phone and a tablet sit on the same line.
        let height = renders.map(\.size.height).max() ?? 0
        let padding = recipe.padding * height
        let spacing = padding * 0.6

        let scales = renders.map { height / $0.size.height }
        let widths = zip(renders, scales).map { $0.size.width * $1 }
        let content = CGSize(
            width: widths.reduce(0, +) + spacing * Double(renders.count - 1),
            height: height
        )
        // A finished background fixes the canvas, such as one rounded to whole pixels for a video.
        let canvas = drawn?.extent.size ?? canvasSize(around: content, margin: padding, aspect: recipe.aspect)

        // The devices sit in the middle of the canvas.
        let originY = (canvas.height - content.height) / 2
        var x = (canvas.width - content.width) / 2
        var shadows = [CIImage]()
        var devices = [CIImage]()

        for (index, render) in renders.enumerated() {
            let move = CGAffineTransform(translationX: x, y: originY)

            if recipe.hasShadow, let shadow = render.shadow {
                shadows.append(scaled(shadow, by: scales[index]).transformed(by: move))
            }

            devices.append(scaled(render.device, by: scales[index]).transformed(by: move))
            x += widths[index] + spacing
        }

        // Shadows first, so one device's shadow never covers its neighbor.
        let background = drawn ?? BackgroundRenderer.image(recipe.background, size: canvas, blurSource: renders.first?.device, blur: recipe.blur)
        let withShadows = shadows.reduce(background) { $1.composited(over: $0) }

        return devices
            .reduce(withShadows) { $1.composited(over: $0) }
            .cropped(to: CGRect(origin: .zero, size: canvas))
    }

    // MARK: - Private Helpers

    /// The smallest canvas of the wanted shape that leaves a margin around the content.
    private static func canvasSize(around content: CGSize, margin: Double, aspect: CanvasAspect) -> CGSize {
        let box = CGSize(width: content.width + margin * 2, height: content.height + margin * 2)

        guard let ratio = aspect.ratio else { return box }

        if box.width / box.height > ratio {
            return CGSize(width: box.width, height: box.width / ratio)
        }

        return CGSize(width: box.height * ratio, height: box.height)
    }

    private static func scaled(_ image: CIImage, by scale: Double) -> CIImage {
        guard abs(scale - 1) > 0.001 else { return image }

        return image.applyingFilter("CILanczosScaleTransform", parameters: [
            kCIInputScaleKey: scale,
            kCIInputAspectRatioKey: 1
        ])
    }
}
