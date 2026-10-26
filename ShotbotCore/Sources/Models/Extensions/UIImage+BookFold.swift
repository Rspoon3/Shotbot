//
//  UIImage+BookFold.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/26/26.
//

import CoreImage
import UIKit

public extension UIImage {
    /// Folds a flat image of an unfolded device around its center crease, like a book opened part of the way.
    ///
    /// Each half is tilted back around the crease so its outer edge comes toward the viewer, then darkened a little,
    /// the left half less than the right. A soft shadow falls beneath the result. Landscape images fold around a
    /// vertical crease and portrait images around a horizontal one.
    ///
    /// - Parameter openingAngle: The angle between the two halves in degrees, from 90 (most closed) to 180 (flat).
    /// - Returns: The folded image on a transparent background, larger than the original to make room for the shadow.
    func bookFolded(openingAngle: Double) -> UIImage? {
        guard let source = CIImage(image: self) else { return nil }

        let isLandscape = size.width >= size.height

        // The fold math works on a vertical crease, so a portrait image is turned a quarter turn first.
        let flat = isLandscape ? source : Self.normalized(source.oriented(.right))
        let width = flat.extent.width
        let height = flat.extent.height
        let centerX = width / 2
        let centerY = height / 2

        let angle = min(max(openingAngle, 90), 180)
        let tilt = (180 - angle) / 2 * .pi / 180
        let focalLength = 5000.0

        /// Where a point of the flat image lands once its half is tilted back around the crease.
        func project(_ x: Double, _ y: Double) -> CGPoint {
            let dx = x - centerX
            let dy = y - centerY
            let depth = -abs(dx) * sin(tilt)
            let scale = focalLength / (focalLength + depth)

            return CGPoint(x: centerX + dx * cos(tilt) * scale, y: centerY + dy * scale)
        }

        func half(from startX: Double, to endX: Double, shade: Double) -> CIImage? {
            let brightness = 1 - shade
            let darkened = flat
                .cropped(to: CGRect(x: startX, y: 0, width: endX - startX, height: height))
                .applyingFilter("CIColorMatrix", parameters: [
                    "inputRVector": CIVector(x: brightness, y: 0, z: 0, w: 0),
                    "inputGVector": CIVector(x: 0, y: brightness, z: 0, w: 0),
                    "inputBVector": CIVector(x: 0, y: 0, z: brightness, w: 0),
                    "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
                ])

            let perspective = CIFilter(name: "CIPerspectiveTransform")
            perspective?.setValue(darkened, forKey: kCIInputImageKey)
            perspective?.setValue(CIVector(cgPoint: project(startX, 0)), forKey: "inputBottomLeft")
            perspective?.setValue(CIVector(cgPoint: project(endX, 0)), forKey: "inputBottomRight")
            perspective?.setValue(CIVector(cgPoint: project(startX, height)), forKey: "inputTopLeft")
            perspective?.setValue(CIVector(cgPoint: project(endX, height)), forKey: "inputTopRight")
            return perspective?.outputImage
        }

        // The further the halves are closed, the darker they get.
        let closedness = (180 - angle) / 90

        // The edge pixels where the halves meet are only partly opaque. The left half reaches a few pixels past the
        // crease, under the right half, so the shadow can't show through as a dark line between them.
        let overlap = max(4, width * 0.002)

        guard
            let left = half(from: 0, to: centerX + overlap, shade: 0.10 * closedness),
            let right = half(from: centerX, to: width, shade: 0.28 * closedness)
        else {
            return nil
        }

        var folded = right.composited(over: left)

        if !isLandscape {
            folded = Self.normalized(folded.oriented(.left))
        }

        // A soft shadow below the folded device, on a canvas with room for it.
        let canvas = folded.extent.insetBy(dx: -folded.extent.width * 0.08, dy: -folded.extent.height * 0.08)
        let shadow = folded
            .applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0.35)
            ])
            .clampedToExtent()
            .applyingGaussianBlur(sigma: folded.extent.width * 0.012)
            .transformed(by: CGAffineTransform(translationX: 0, y: -folded.extent.height * 0.016))
            .cropped(to: canvas)

        let result = folded.composited(over: shadow)

        guard let cgImage = CIContext().createCGImage(result, from: canvas) else { return nil }

        return UIImage(cgImage: cgImage, scale: 1, orientation: .up)
    }

    /// Moves a Core Image image so its extent starts at the origin, which `oriented(_:)` can change.
    private static func normalized(_ image: CIImage) -> CIImage {
        image.transformed(by: CGAffineTransform(translationX: -image.extent.origin.x, y: -image.extent.origin.y))
    }
}
