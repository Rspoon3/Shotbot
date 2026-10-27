//
//  UIImage+ScreenMask.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/25/26.
//

import UIKit

public extension UIImage {
    /// Draws a screenshot clipped to a screen mask, then draws this device frame on top.
    ///
    /// - Parameters:
    ///   - screenshot: The screenshot to place in the frame. It must be the same size as the mask.
    ///   - offset: Where the screenshot's top-left corner sits in the frame.
    ///   - mask: A screen mask cropped to the frame's screen opening, or `nil` to draw the screenshot unclipped.
    /// - Returns: The framed screenshot on a transparent background.
    func overlaying(_ screenshot: UIImage, at offset: CGPoint, clippedTo mask: CGImage?) -> UIImage {
        let renderer = UIGraphicsImageRenderer(
            size: size,
            format: .singleScale
        )

        return renderer.image { context in
            let cgContext = context.cgContext
            let screenRect = CGRect(origin: offset, size: screenshot.size)

            cgContext.saveGState()

            if let mask {
                // `clip(to:mask:)` expects a bottom-left origin, while the renderer's context is flipped.
                // The clip is stored in device space, so flipping back afterward keeps it in place.
                cgContext.translateBy(x: 0, y: size.height)
                cgContext.scaleBy(x: 1, y: -1)
                cgContext.clip(
                    to: CGRect(
                        x: screenRect.minX,
                        y: size.height - screenRect.maxY,
                        width: screenRect.width,
                        height: screenRect.height
                    ),
                    mask: mask
                )
                cgContext.scaleBy(x: 1, y: -1)
                cgContext.translateBy(x: 0, y: -size.height)
            }

            screenshot.draw(in: screenRect)

            cgContext.restoreGState()

            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
