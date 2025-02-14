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
        
        let squareSize = max(framedScreenshot.size.width, framedScreenshot.size.height)
        let backgroundSize = squareSize * 1.1
        
        let color = UIColor.random().image(size: .init(width: backgroundSize, height: backgroundSize))!
        
        print(framedScreenshot.size, backgroundSize)
        
        return color.overlayWith(image: framedScreenshot)!
        
        // Add a background
//        let backgroundImage = framedScreenshot.redrawing(overColor: .systemRed)
//        let backgroundImage = framedScreenshot.withBackground(color: .systemBlue, padding: 150)!

//        let backgroundImage = framedScreenshot.withGradientBackground(colors: [.systemRed, .systemOrange, .systemBlue])!

        
//        return backgroundImage
    }
}

import UIKit

extension UIColor {
    public func image(size: CGSize) -> UIImage? {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        context.setFillColor(self.cgColor)
        context.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}

extension UIImage {
    public func overlayWith(image: UIImage, position: CGPoint? = nil) -> UIImage? {
        let baseSize = self.size
        let overlaySize = image.size

        // Use the overlay image's original size, ignoring the aspect ratio
        let targetWidth = overlaySize.width
        let targetHeight = overlaySize.height

        // Center the overlay image on the base image
        let targetRect = CGRect(
            x: position?.x ?? (baseSize.width - targetWidth) / 2,
            y: position?.y ?? (baseSize.height - targetHeight) / 2,
            width: targetWidth,
            height: targetHeight
        )

        // Begin the graphics context
        UIGraphicsBeginImageContextWithOptions(baseSize, false, self.scale)
        
        // Draw the base image
        self.draw(in: CGRect(origin: .zero, size: baseSize))
        
        // Draw the overlay image
        image.draw(in: targetRect)
        
        // Get the final image
        let combinedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return combinedImage
    }
}




extension UIImage {
    func withBackground(color: UIColor, size: CGSize? = nil, padding: CGFloat = 0) -> UIImage? {
        let newSize = size ?? self.size
        let rect = CGRect(origin: .zero, size: newSize)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Fill the background with the specified color
        context.setFillColor(color.cgColor)
        context.fill(rect)

        // Calculate the available size after padding is applied
        let availableWidth = newSize.width - 2 * padding
        let availableHeight = newSize.height - 2 * padding

        // Calculate the aspect ratio of the original image
        let aspectRatio = self.size.width / self.size.height

        // Determine the final size of the image within the padded area
        var targetWidth: CGFloat
        var targetHeight: CGFloat

        if availableWidth / aspectRatio <= availableHeight {
            targetWidth = availableWidth
            targetHeight = availableWidth / aspectRatio
        } else {
            targetHeight = availableHeight
            targetWidth = availableHeight * aspectRatio
        }

        // Center the image within the padded area
        let targetRect = CGRect(
            x: padding + (availableWidth - targetWidth) / 2,
            y: padding + (availableHeight - targetHeight) / 2,
            width: targetWidth,
            height: targetHeight
        )

        // Draw the original image on top of the background
        self.draw(in: targetRect)

        // Get the new image
        let imageWithBackground = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return imageWithBackground
    }
}

extension UIImage {
    func withGradientBackground(colors: [UIColor], size: CGSize? = nil) -> UIImage? {
        let newSize = size ?? self.size
        let rect = CGRect(origin: .zero, size: newSize)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Create a gradient
        let cgColors = colors.map { $0.cgColor }
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cgColors as CFArray, locations: nil) else { return nil }

        // Draw the gradient in the context
        let startPoint = CGPoint(x: 0, y: 0)
        let endPoint = CGPoint(x: 0, y: newSize.height)
        context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])

        // Draw the original image on top of the gradient
        self.draw(in: CGRect(x: (newSize.width - self.size.width) / 2,
                             y: (newSize.height - self.size.height) / 2,
                             width: self.size.width,
                             height: self.size.height))

        // Get the new image
        let imageWithGradientBackground = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return imageWithGradientBackground
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

import CoreGraphics

public extension CGSize {
    static func +<T: Numeric>(lhs: CGSize, rhs: T) -> CGSize where T: BinaryInteger {
        return CGSize(width: lhs.width + CGFloat(rhs), height: lhs.height + CGFloat(rhs))
    }

    static func +<T: Numeric>(lhs: T, rhs: CGSize) -> CGSize where T: BinaryInteger {
        return CGSize(width: rhs.width + CGFloat(lhs), height: rhs.height + CGFloat(lhs))
    }

    static func +<T: Numeric>(lhs: CGSize, rhs: T) -> CGSize where T: BinaryFloatingPoint {
        return CGSize(width: lhs.width + CGFloat(rhs), height: lhs.height + CGFloat(rhs))
    }

    static func +<T: Numeric>(lhs: T, rhs: CGSize) -> CGSize where T: BinaryFloatingPoint {
        return CGSize(width: rhs.width + CGFloat(lhs), height: rhs.height + CGFloat(lhs))
    }
}
