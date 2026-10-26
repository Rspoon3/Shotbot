//
//  UIImage+Extension.swift
//  Testing
//
//  Created by Richard Witherspoon on 4/19/23.
//

import UIKit
import AVFoundation

public extension UIImage {
    convenience init?(named name: String, in bundle: Bundle) {
        self.init(named: name, in: bundle, with: nil)
    }
    
    /// Resizes an image to a specified size
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(
            size: size,
            format: .singleScale
        )
        
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// Scales an image to a percentage of itself while keeping its aspect ratio
    func scaled(to percentage: Double) -> UIImage {
        guard percentage < 1 else { return self }
        
        let scaledSize = CGSize(width: size.width * percentage, height: size.height * percentage)
        let availableRect = AVMakeRect(aspectRatio: size, insideRect: .init(origin: .zero, size: scaledSize))
        let targetSize = availableRect.size
        let renderer = UIGraphicsImageRenderer(
            size: targetSize,
            format: .singleScale
        )
            
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    /// Creates a framed screenshot based on the image quality passed in.
    ///
    /// Only succeeds for unambiguous device matches. For ambiguous matches
    /// (e.g., Display Zoom conflicts), use the overload that accepts a `DeviceInfo`.
    func framedScreenshot(quality: ImageQuality) throws -> UIFramedScreenshot {
        let result = DeviceInfo.match(for: size)

        guard case .exact(let device) = result,
              let framedScreenshot = device.framed(using: self)?.scaled(to: quality.value)
        else {
            throw SBError.unsupportedImage
        }

        return framedScreenshot
    }

    /// Creates a framed screenshot using a pre-resolved device.
    func framedScreenshot(quality: ImageQuality, device: DeviceInfo) throws -> UIFramedScreenshot {
        guard let framedScreenshot = device.framed(using: self)?.scaled(to: quality.value) else {
            throw SBError.unsupportedImage
        }

        return framedScreenshot
    }
}

public extension Array where Element: UIImage {
    /// Combines multiple images horizontally
    func combineHorizontally() -> UIImage {
        let imagesWidth = map(\.size.width).reduce(0, +)
        let spacing = CGFloat(Int((imagesWidth / CGFloat(count)) * 0.02))
        let maxWidth = self.compactMap { $0.size.width }.max()
        let maxHeight = self.compactMap { $0.size.height }.max() ?? 0
        let maxSize = CGSize(width: maxWidth ?? 0, height: maxHeight)
        let totalSpacing = spacing * CGFloat(count - 1)
        let size = CGSize(width: imagesWidth + totalSpacing, height: maxSize.height)
        let rendererer = UIGraphicsImageRenderer(size: size, format: .singleScale)
        
        return rendererer.image { context in
            var previousX: CGFloat = 0
            
            for (index, image) in self.enumerated() {
                let insideRect: CGRect
                let x: CGFloat
                
                if index == 0 {
                    x = 0
                } else {
                    x = previousX + spacing
                }
                
                insideRect = CGRect(
                    x: x,
                    y: 0,
                    width: image.size.width,
                    height: maxSize.height
                )
                
                previousX = insideRect.maxX
                
                let rect = AVMakeRect(
                    aspectRatio: image.size,
                    insideRect: insideRect
                )
                
                image.draw(in: rect)
            }
        }
    }
}
