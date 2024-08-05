//
//  PlatformImage+Extension.swift
//  Testing
//
//  Created by Richard Witherspoon on 4/19/23.
//

#if os(macOS)
import SwiftUI
#else
import UIKit
#endif

import AVFoundation

public extension PlatformImage {
    convenience init?(named name: String, in bundle: Bundle) {
#if os(macOS)                                                                   
        self.init(resource: .init(name: name, bundle: bundle))
#else
        self.init(named: name, in: bundle, with: nil)
#endif
    }
    
    /// Resizes an image to a specified size
    func resized(to size: CGSize) -> PlatformImage {
        let rect = CGRect(origin: .zero, size: size)

#if canImport(UIKit)
        let render = UIGraphicsImageRenderer(
            size: size,
            format: .singleScale
        )
        
        return render.image { _ in
            draw(in: rect)
        }
#else
        let newImage = NSImage(size: size)
        
        newImage.lockFocus()
        defer { newImage.unlockFocus() }
        
        self.draw(
            in: rect,
            from: NSRect(origin: .zero, size: self.size),
            operation: .sourceOver,
            fraction: 1.0
        )
        
        return newImage
#endif
    }
    
    /// Scales an image to a percentage of itself while keeping its aspect ratio
    func scaled(to percentage: Double) -> PlatformImage {
        guard percentage < 1 else { return self }
        
        let scaledSize = CGSize(width: size.width * percentage, height: size.height * percentage)
        let availableRect = AVMakeRect(aspectRatio: size, insideRect: .init(origin: .zero, size: scaledSize))
        let targetSize = availableRect.size
        let rect = CGRect(origin: .zero, size: targetSize)
        
#if canImport(UIKit)
        let render = UIGraphicsImageRenderer(
            size: targetSize,
            format: .singleScale
        )
        
        return render.image { _ in
            draw(in: rect)
        }
#else
        let newImage = NSImage(size: targetSize)
        newImage.lockFocus()
        
        defer { newImage.unlockFocus() }
        
        self.draw(
            in: rect,
            from: NSRect(origin: .zero, size: self.size),
            operation: .sourceOver,
            fraction: 1.0
        )
        
        return newImage
#endif
    }
    
    /// Merges two images together, one on top of the other
    func merge(
        with topImage: PlatformImage,
        offset: CGPoint,
        alpha: CGFloat = 1
    ) -> PlatformImage {
        let rect = CGRect(
            origin: .zero,
            size: size
        )
        let topRect = CGRect(
            origin: offset,
            size: topImage.size
        )

#if canImport(UIKit)
        let render = UIGraphicsImageRenderer(
            size: size,
            format: .singleScale
        )
        
        return render.image { _ in
            draw(in: rect)
            
            topImage.draw(
                in: topRect,
                blendMode: .normal,
                alpha: alpha
            )
        }
#else
        let newImage = NSImage(size: self.size)
        
        newImage.lockFocus()
        defer { newImage.unlockFocus() }
        
        self.draw(in: rect)
        
        topImage.draw(
            in: topRect,
            from: NSRect(
                origin: .zero,
                size: topImage.size
            ),
            operation: .sourceOver,
            fraction: alpha
        )
        
        return newImage
#endif
    }
    
    /// Clips the four corners of an image by a specified amount
    func clipEdges(amount: CGFloat) -> PlatformImage {
        let rect = CGRect(origin: .zero, size: size)

#if canImport(UIKit)
        let render = UIGraphicsImageRenderer(
            size: size,
            format: .singleScale
        )
            
        return render.image { _ in
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
#else
        let newImage = NSImage(size: self.size)
        
        newImage.lockFocus()
        defer { newImage.unlockFocus() }
        
        let path = NSBezierPath()
        
        // Top Left
        path.move(to: CGPoint(x: rect.minX + amount, y: rect.minY))
        
        // Top Right
        path.line(to: CGPoint(x: rect.maxX - amount, y: rect.minY))
        path.line(to: CGPoint(x: rect.maxX, y: rect.minY + amount))
        
        // Bottom Right
        path.line(to: CGPoint(x: rect.maxX, y: rect.maxY - amount))
        path.line(to: CGPoint(x: rect.maxX - amount, y: rect.maxY))
        
        // Bottom Left
        path.line(to: CGPoint(x: rect.minX + amount, y: rect.maxY))
        path.line(to: CGPoint(x: rect.minX, y: rect.maxY - amount))
        
        path.line(to: CGPoint(x: rect.minX, y: rect.minY + amount))
        path.close()
        
        path.addClip()
        self.draw(in: rect)
        
        return newImage

        #endif
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

public extension Array where Element: PlatformImage {
    /// Combines multiple images horizontally
    func combineHorizontally() -> PlatformImage {
        let imagesWidth = map(\.size.width).reduce(0, +)
        let spacing = CGFloat(Int((imagesWidth / CGFloat(count)) * 0.02))
        let maxWidth = self.compactMap { $0.size.width }.max()
        let maxHeight = self.compactMap { $0.size.height }.max() ?? 0
        let maxSize = CGSize(width: maxWidth ?? 0, height: maxHeight)
        let totalSpacing = spacing * CGFloat(count - 1)
        let size = CGSize(width: imagesWidth + totalSpacing, height: maxSize.height)
        
#if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: size, format: .singleScale)
        
        return renderer.image { context in
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
#else
        let newImage = NSImage(size: size)
        
        newImage.lockFocus()
        defer { newImage.unlockFocus() }
        
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
        
        return newImage
#endif
    }
}
