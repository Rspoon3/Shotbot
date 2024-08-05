//
//  ImageManaging.swift
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

public protocol ImageManaging {
    func latestScreenshot(from url: URL) async throws -> PlatformImage
    func latestScreenshot(targetSize: CGSize) async throws -> (image: PlatformImage, assetID: String)
    func multipleScreenshots(from url: URL) async throws -> [PlatformImage]
}
