//
//  ImageCombiner.swift
//  ShotbotCore
//
//  Created by Richard Witherspoon on 7/24/24.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

import OSLog
import Models
import Persistence

public protocol ImageCombining {
    func createCombinedImage(
        from images: [PlatformImage],
        imageQuality: Double
    ) async throws -> ShareableImage
}

/// An object responsible for combing images horizontally.
public struct ImageCombiner: ImageCombining {
    
    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Public
    
    /// Combines images Horizontally with scaling to keep consistent spacing
    public func createCombinedImage(
        from images: [PlatformImage],
        imageQuality: Double
    ) async throws -> ShareableImage {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInteractive).async {
                let logger = Logger(category: ImageCombiner.self)
                logger.info("Starting combined image task.")
                
                defer {
                    logger.info("Ending combined image task.")
                }
                
                let imagesWidth = images.map(\.size.width).reduce(0, +)
                let resizedImages = images.map { image in
                    let widthScale = (image.size.width / imagesWidth)
                    let scale = max(widthScale, imageQuality)
                    let size = CGSize(
                        width: image.size.width * scale,
                        height: image.size.height * scale
                    )
                    return image.resized(to: size)
                }
                
                let combined = resizedImages.combineHorizontally()
                
                guard let data = combined.pngData() else {
                    logger.error("No combined image png data")
                    continuation.resume(throwing: SBError.noImageData)
                    return
                }
                
                let temporaryURL = URL.temporaryDirectory.appending(path: "Combined \(UUID().uuidString).png")
                
                do {
                    try data.write(to: temporaryURL)
                    logger.info("Saving combined data to temporary url.")
                    
                    let image = ShareableImage(framedScreenshot: combined, url: temporaryURL)
                    
                    continuation.resume(returning: image)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
