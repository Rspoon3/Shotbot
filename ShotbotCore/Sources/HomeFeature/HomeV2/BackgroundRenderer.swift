//
//  BackgroundRenderer.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import CoreImage
import Models
import UIKit

/// Draws backgrounds with Core Image, so they cost almost nothing to change and look the same at every size.
enum BackgroundRenderer {
    /// A background filling a rectangle that starts at the origin.
    /// - Parameters:
    ///   - style: Which background to draw.
    ///   - size: The size to fill.
    ///   - blurSource: The picture the blurred style is made from.
    ///   - blur: How much to blur the photo style.
    static func image(_ style: BackgroundStyle, size: CGSize, blurSource: CIImage? = nil, blur: BackgroundBlur = .none) -> CIImage {
        let rect = CGRect(origin: .zero, size: size)

        switch style {
        case .transparent:
            return CIImage(color: .clear).cropped(to: rect)
        case .white:
            return CIImage(color: .white).cropped(to: rect)
        case .black:
            return CIImage(color: CIColor(red: 0.04, green: 0.04, blue: 0.05)).cropped(to: rect)
        case .sunset:
            return linear(from: CIColor(red: 1, green: 0.62, blue: 0.3), to: CIColor(red: 0.62, green: 0.18, blue: 0.62), in: size)
        case .ocean:
            return linear(from: CIColor(red: 0.2, green: 0.62, blue: 0.95), to: CIColor(red: 0.04, green: 0.12, blue: 0.38), in: size)
        case .aurora:
            return aurora(in: size)
        case .blurred:
            return blurred(blurSource, in: size)
        case .photo:
            return blurred(filled(photo, in: size), sigma: size.height * blur.strength)
        }
    }

    /// A small picture of a background, for choosing between them.
    @MainActor
    static func thumbnail(_ style: BackgroundStyle) -> UIImage? {
        if let cached = thumbnails[style] { return cached }

        let size = CGSize(width: 96, height: 96)
        let image = Self.image(style, size: size, blurSource: aurora(in: size))

        guard let cgImage = LayerStore.shared.context.createCGImage(image, from: CGRect(origin: .zero, size: size)) else {
            return nil
        }

        let thumbnail = UIImage(cgImage: cgImage)
        thumbnails[style] = thumbnail
        return thumbnail
    }

    @MainActor private static var thumbnails: [BackgroundStyle: UIImage] = [:]

    // MARK: - Private Helpers

    private static func linear(from start: CIColor, to end: CIColor, in size: CGSize) -> CIImage {
        // Top-left to bottom-right, in Core Image's bottom-left coordinates.
        CIFilter(name: "CILinearGradient", parameters: [
            "inputPoint0": CIVector(x: 0, y: size.height),
            "inputPoint1": CIVector(x: size.width, y: 0),
            "inputColor0": start,
            "inputColor1": end
        ])!.outputImage!.cropped(to: CGRect(origin: .zero, size: size))
    }

    private static func aurora(in size: CGSize) -> CIImage {
        let rect = CGRect(origin: .zero, size: size)
        let reach = max(size.width, size.height)
        var image = CIImage(color: CIColor(red: 0.03, green: 0.05, blue: 0.14)).cropped(to: rect)

        let blobs: [(x: Double, y: Double, radius: Double, color: CIColor)] = [
            (0.2, 0.85, 0.7, CIColor(red: 0.1, green: 0.85, blue: 0.6, alpha: 0.75)),
            (0.85, 0.6, 0.65, CIColor(red: 0.45, green: 0.3, blue: 0.95, alpha: 0.75)),
            (0.45, 0.1, 0.7, CIColor(red: 0.95, green: 0.3, blue: 0.6, alpha: 0.6))
        ]

        for blob in blobs {
            let glow = CIFilter(name: "CIRadialGradient", parameters: [
                "inputCenter": CIVector(x: size.width * blob.x, y: size.height * blob.y),
                "inputRadius0": 0,
                "inputRadius1": reach * blob.radius,
                "inputColor0": blob.color,
                "inputColor1": CIColor(red: 0, green: 0, blue: 0, alpha: 0)
            ])!.outputImage!.cropped(to: rect)

            image = glow.composited(over: image)
        }

        return image
    }

    private static let photo = BackgroundImages.reputation.map { CIImage(cgImage: $0) }

    /// A picture scaled to cover a rectangle, cropped evenly on the sides that overflow.
    private static func filled(_ source: CIImage?, in size: CGSize) -> CIImage {
        let rect = CGRect(origin: .zero, size: size)

        guard let source, source.extent.width > 0, source.extent.height > 0 else {
            return CIImage(color: CIColor(red: 0.5, green: 0.5, blue: 0.55)).cropped(to: rect)
        }

        let fill = max(size.width / source.extent.width, size.height / source.extent.height)
        let scaled = source.applyingFilter("CILanczosScaleTransform", parameters: [
            kCIInputScaleKey: fill,
            kCIInputAspectRatioKey: 1
        ])

        return scaled
            .transformed(by: CGAffineTransform(
                translationX: (size.width - scaled.extent.width) / 2 - scaled.extent.minX,
                y: (size.height - scaled.extent.height) / 2 - scaled.extent.minY
            ))
            .cropped(to: rect)
    }

    private static func blurred(_ source: CIImage?, in size: CGSize) -> CIImage {
        let rect = CGRect(origin: .zero, size: size)

        // Fill the background with the picture, then blur it until only its colors are left.
        return blurred(filled(source, in: size), sigma: size.height * 0.04)
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 1.4,
                kCIInputBrightnessKey: -0.05
            ])
            .cropped(to: rect)
    }

    /// A Gaussian blur that keeps the picture's edges sharp instead of fading them to transparent.
    private static func blurred(_ image: CIImage, sigma: Double) -> CIImage {
        guard sigma > 0 else { return image }

        return image
            .clampedToExtent()
            .applyingGaussianBlur(sigma: sigma)
            .cropped(to: image.extent)
    }
}
