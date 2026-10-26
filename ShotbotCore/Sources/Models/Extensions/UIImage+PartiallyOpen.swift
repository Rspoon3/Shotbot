//
//  UIImage+PartiallyOpen.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/26/26.
//

import CoreImage
import UIKit

public extension UIImage {
    /// Opens a flat image of an unfolded device part of the way around its center crease, like a book.
    ///
    /// The image is bent as one continuous surface. Away from the crease each side is a flat panel tilted back so its
    /// outer edge comes toward the viewer. Near the crease the surface curves smoothly from one tilt to the other, so
    /// there is no hard edge where the sides meet. The brightness follows the slope of the surface, darker toward the
    /// right (or top) side, and changes gradually across the bend. A soft shadow falls beneath the result. Landscape
    /// images bend around a vertical crease and portrait images around a horizontal one.
    ///
    /// - Parameter openingAngle: The angle between the two sides in degrees, from 90 (most closed) to 180 (flat).
    /// - Returns: The partially open image on a transparent background, larger than the original to make room for the shadow.
    func partiallyOpened(openingAngle: Double) -> UIImage? {
        guard let source = CIImage(image: self) else { return nil }

        let isLandscape = size.width >= size.height

        // The bending math works on a vertical crease, so a portrait image is turned a quarter turn first.
        let flat = isLandscape ? source : Self.normalized(source.oriented(.right))
        let width = flat.extent.width
        let height = flat.extent.height
        let centerX = width / 2
        let centerY = height / 2

        let angle = min(max(openingAngle, 90), 180)
        let tilt = (180 - angle) / 2 * .pi / 180
        let closedness = (180 - angle) / 90
        let focalLength = 5000.0

        // How tightly the surface curves at the crease. A smaller radius gives a sharper crease.
        let bendRadius = width * 0.018

        // The surface, one pixel of the flat image at a time outward from the crease. The slope tilts smoothly from
        // flat at the crease toward the full tilt of the panel, and each step moves sideways and toward the viewer.
        let steps = Int(centerX.rounded(.up)) + 4
        var sideways = [Double](repeating: 0, count: steps)
        var depth = [Double](repeating: 0, count: steps)

        for step in 1..<steps {
            let slope = tilt * tanh((Double(step) - 0.5) / bendRadius)
            sideways[step] = sideways[step - 1] + cos(slope)
            depth[step] = depth[step - 1] - sin(slope)
        }

        /// How far sideways and toward the viewer a point `distance` pixels from the crease sits on the surface.
        func surface(at distance: Double) -> (sideways: Double, depth: Double) {
            let index = min(Int(distance), steps - 2)
            let fraction = distance - Double(index)

            return (
                sideways[index] + (sideways[index + 1] - sideways[index]) * fraction,
                depth[index] + (depth[index + 1] - depth[index]) * fraction
            )
        }

        /// Where a point of the flat image lands on screen once it is on the bent surface.
        func project(_ x: Double, _ y: Double) -> CGPoint {
            let dx = x - centerX
            let point = surface(at: abs(dx))
            let scale = focalLength / (focalLength + point.depth)

            return CGPoint(
                x: centerX + (dx < 0 ? -point.sideways : point.sideways) * scale,
                y: centerY + (y - centerY) * scale
            )
        }

        /// How much darker the surface is `dx` pixels from the crease, going from 10% on the left side to 28% on the
        /// right side when fully closed, smoothly across the bend.
        func shade(at dx: Double) -> Double {
            closedness * (0.19 + 0.09 * tanh(dx / bendRadius))
        }

        // Each piece reaches a few pixels under the next one, so the shadow can't show through the half-transparent
        // edge pixels between them as a dark line.
        let overlap = max(2, width * 0.001)

        func piece(from startX: Double, to endX: Double) -> CIImage? {
            let reach = min(endX + overlap, width)
            let brightness = 1 - shade(at: (startX + endX) / 2 - centerX)
            let darkened = flat
                .cropped(to: CGRect(x: startX, y: 0, width: reach - startX, height: height))
                .applyingFilter("CIColorMatrix", parameters: [
                    "inputRVector": CIVector(x: brightness, y: 0, z: 0, w: 0),
                    "inputGVector": CIVector(x: 0, y: brightness, z: 0, w: 0),
                    "inputBVector": CIVector(x: 0, y: 0, z: brightness, w: 0),
                    "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
                ])

            let perspective = CIFilter(name: "CIPerspectiveTransform")
            perspective?.setValue(darkened, forKey: kCIInputImageKey)
            perspective?.setValue(CIVector(cgPoint: project(startX, 0)), forKey: "inputBottomLeft")
            perspective?.setValue(CIVector(cgPoint: project(reach, 0)), forKey: "inputBottomRight")
            perspective?.setValue(CIVector(cgPoint: project(startX, height)), forKey: "inputTopLeft")
            perspective?.setValue(CIVector(cgPoint: project(reach, height)), forKey: "inputTopRight")
            return perspective?.outputImage
        }

        // Far from the crease the surface is a flat panel, so each side is a single piece. Around the crease it is
        // cut into thin strips, so the curve and the shading change smoothly across it.
        let bendReach = bendRadius * 4
        let bendStart = max(0, centerX - bendReach)
        let bendEnd = min(width, centerX + bendReach)
        let stripWidth = 3.0

        var edges = [0.0, bendStart]
        edges += Array(stride(from: bendStart + stripWidth, to: bendEnd, by: stripWidth))
        edges += [bendEnd, width]

        let pieces = zip(edges, edges.dropFirst()).compactMap { start, end in
            end > start ? piece(from: start, to: end) : nil
        }

        guard var opened = pieces.first else { return nil }

        // Left to right, so each piece covers the overlap of the one before it.
        for next in pieces.dropFirst() {
            opened = next.composited(over: opened)
        }

        if !isLandscape {
            opened = Self.normalized(opened.oriented(.left))
        }

        // A soft shadow below the partially open device, on a canvas with room for it. Pad with transparent pixels instead of
        // repeating the edge pixels, which would smear the shadow outward from wherever the device touches the edge.
        let canvas = opened.extent.insetBy(dx: -opened.extent.width * 0.08, dy: -opened.extent.height * 0.08)
        let transparent = CIImage(color: .clear).cropped(to: canvas)
        let shadow = opened
            .composited(over: transparent)
            .applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0.35)
            ])
            .applyingGaussianBlur(sigma: opened.extent.width * 0.012)
            .transformed(by: CGAffineTransform(translationX: 0, y: -opened.extent.height * 0.016))
            .cropped(to: canvas)

        let result = opened.composited(over: shadow)

        guard let cgImage = CIContext().createCGImage(result, from: canvas) else { return nil }

        return UIImage(cgImage: cgImage, scale: 1, orientation: .up)
    }

    /// Moves a Core Image image so its extent starts at the origin, which `oriented(_:)` can change.
    private static func normalized(_ image: CIImage) -> CIImage {
        image.transformed(by: CGAffineTransform(translationX: -image.extent.origin.x, y: -image.extent.origin.y))
    }
}
