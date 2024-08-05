//
//  MockImageManager.swift
//  
//
//  Created by Richard Witherspoon on 7/22/24.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

import Models

#if DEBUG
public struct MockImageManager: ImageManaging {
    
    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Public
    
    public func latestScreenshot(from url: URL) async throws -> PlatformImage {
        return PlatformImage(systemName: "star")!
    }
    
    public func latestScreenshot(targetSize: CGSize) async throws -> (image: PlatformImage, assetID: String) {
        let names = ["car", "house", "star", "circle"]
        let random = PlatformImage(systemName: names.randomElement()!)!
        
        return (random, UUID().uuidString)
    }
    
    public func multipleScreenshots(from url: URL) async throws -> [PlatformImage] {
        return []
    }
}
#endif
