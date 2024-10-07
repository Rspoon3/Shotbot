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
    
    /// Merges two images together, one on top of the other
    func merge(
        with topImage: UIImage,
        offset: CGPoint,
        alpha: CGFloat = 1
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(
            size: size,
            format: .singleScale
        )
        
        return renderer.image { _ in
            let rect = CGRect(
                origin: .zero,
                size: size
            )
            
            draw(in: rect)
            
            topImage.draw(
                in: .init(
                    origin: offset,
                    size: topImage.size
                ),
                blendMode: .normal,
                alpha: alpha
            )
        }
    }
    
    func overlayWithLargerCenteredImage(_ largerImage: UIImage) -> UIImage? {
        let largerSize = largerImage.size
        
        // Determine the canvas size to fit both images
        let canvasSize = CGSize(
            width: max(size.width, largerSize.width),
            height: max(size.height, largerSize.height)
        )
        
        let renderer = UIGraphicsImageRenderer(
            size: canvasSize,
            format: .singleScale
        )
        
        return renderer.image { context in
            // Calculate the origin points to center the images
            let smallerOrigin = CGPoint(
                x: (canvasSize.width - size.width) / 2,
                y: (canvasSize.height - size.height) / 2
            )
            let largerOrigin = CGPoint(
                x: (canvasSize.width - largerSize.width) / 2,
                y: (canvasSize.height - largerSize.height) / 2
            )
            
            // Draw the smaller image first
            draw(
                in: CGRect(
                    origin: smallerOrigin,
                    size: size
                )
            )
            
            // Draw the larger image on top
            largerImage.draw(
                in: CGRect(
                    origin: largerOrigin,
                    size: largerSize
                )
            )
        }
    }
    
    /// Clips the four corners of an image by a specified amount
    func clipEdges(amount: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(
            size: size,
            format: .singleScale
        )
            
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath()
            
            //Top Left
            path.move(to: CGPoint(x: rect.minX + amount, y: rect.minY))
            
            //Top Right
            path.addLine(to: CGPoint(x: rect.maxX - amount, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + amount))
            
            //Bottom Right
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - amount))
            path.addLine(to: CGPoint(x: rect.maxX - amount, y: rect.maxY))
            
            //Bottom Left
            path.addLine(to: CGPoint(x: rect.minX + amount, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - amount))
            
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + amount))
            path.close()
            
            path.addClip()
            draw(in: rect)
        }
    }
    
    /// Adds a corner radius to the image.
    func withRoundedCorners(radius: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(
            size: size,
            format: .singleScale
        )
        
        return renderer.image { context in
            let rect = CGRect(
                origin: .zero,
                size: size
            )
            
            // Create a rounded path with the given radius
            let path = UIBezierPath(
                roundedRect: rect,
                cornerRadius: radius
            )
            
            // Clip the context to the rounded path
            path.addClip()
            
            // Draw the image inside the clipped context
            draw(in: rect)
        }
    }
    
    /// Creates a framed screenshot based on the image quality passed in
    func framedScreenshot(quality: ImageQuality) throws -> UIFramedScreenshot {
        guard
            let device = DeviceInfo.all().first(where: {$0.inputSize == size}),
            let framedScreenshot = device.framed(using: self)?.scaled(to: quality.value)
        else {
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
