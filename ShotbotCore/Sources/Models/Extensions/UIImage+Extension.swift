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
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// Scales an image to a percentage of itself while keeping its aspect ratio
    func scaled(to percentage: Double) -> UIImage {
        guard percentage < 1 else { return self }
        
        let scaledSize = CGSize(width: size.width * percentage, height: size.height * percentage)
        let availableRect = AVMakeRect(aspectRatio: size, insideRect: .init(origin: .zero, size: scaledSize))
        let targetSize = availableRect.size
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    /// Merges two images together, one on top of the other
    func merge(
        with topImage: UIImage,
        offset: CGPoint,
        alpha: CGFloat = 1
    ) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            let rect = CGRect(origin: .zero, size: size)
            
            draw(in: rect)
            
            topImage.draw(
                in: .init(origin: offset, size: topImage.size),
                blendMode: .normal,
                alpha: alpha)
        }
    }
    
    /// Clips the four corners of an image by a specified amount
    func clipEdges(amount: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
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
    
    func framedScreenshot(quality: ImageQuality) throws -> UIFramedScreenshot {
        guard
            let device = DeviceInfo.all().first(where: {$0.inputSize == size}),
            let framedScreenshot = device.framed(using: self)?.scaled(to: quality.value)
        else {
            throw SBError.noImage
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
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { (context) in
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
