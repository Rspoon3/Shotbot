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

        let folder = PartiallyOpenFolder(size: source.extent.size, openingAngle: openingAngle)

        guard let opened = folder.open(source) else { return nil }

        let canvas = PartiallyOpenFolder.canvas(for: opened)
        let result = opened.composited(over: PartiallyOpenFolder.shadow(of: opened, in: canvas))

        guard let cgImage = CIContext().createCGImage(result, from: canvas) else { return nil }

        return UIImage(cgImage: cgImage, scale: 1, orientation: .up)
    }
}
