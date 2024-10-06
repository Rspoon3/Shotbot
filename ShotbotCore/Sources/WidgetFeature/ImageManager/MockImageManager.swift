//
//  MockImageManager.swift
//  
//
//  Created by Richard Witherspoon on 7/22/24.
//

import UIKit

#if DEBUG
public struct MockImageManager: ImageManaging {
    
    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Public
    
    public func latestScreenshot(from url: URL) async throws -> UIImage {
        return UIImage(systemName: "star")!
    }
    
    public func latestScreenshot(targetSize: CGSize) async throws -> (image: UIImage, assetID: String) {
        let names = ["car", "house", "star", "circle"]
        let random = UIImage(systemName: names.randomElement()!)!
        
        return (random, UUID().uuidString)
    }
    
    public func multipleScreenshots(within duration: Int) async throws -> [UIImage] {
        return []
    }
}
#endif
