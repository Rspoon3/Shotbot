//
//  ScreenMaskCache.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/25/26.
//

import ImageIO
import UIKit

/// Loads and caches the bundled screen masks used by `maskedOverlay` device frames.
///
/// A screen mask is an 8-bit grayscale PNG cropped to a frame's screen opening, where white is screen
/// and black is everything else. Masks are generated from the frame artwork by
/// `Scripts/generate_screen_masks.py`, and the Models tests verify they still match the frames.
enum ScreenMaskCache {
    // `NSCache` is thread-safe, so sharing one instance across threads is safe.
    nonisolated(unsafe) private static let cache = NSCache<NSString, CGImage>()

    /// Returns the screen mask for a device frame, decoding it on first use.
    /// - Parameter deviceFrame: The device frame's asset name. The mask file is named `<deviceFrame> Mask.png`.
    static func mask(for deviceFrame: String) -> CGImage? {
        if let cached = cache.object(forKey: deviceFrame as NSString) {
            return cached
        }

        guard
            let url = Bundle.module.url(forResource: "\(deviceFrame) Mask", withExtension: "png"),
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
            let mask = grayscale(image)
        else {
            return nil
        }

        cache.setObject(mask, forKey: deviceFrame as NSString)
        return mask
    }

    /// Redraws an image as 8-bit grayscale with no alpha, the format `CGContext.clip(to:mask:)` requires.
    private static func grayscale(_ image: CGImage) -> CGImage? {
        guard let context = CGContext(
            data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return nil
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return context.makeImage()
    }
}
