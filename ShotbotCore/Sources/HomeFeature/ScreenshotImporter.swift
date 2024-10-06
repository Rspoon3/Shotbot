//
//  ScreenshotImporter.swift
//  ShotbotCore
//
//  Created by Richard Witherspoon on 7/24/24.
//

import SwiftUI
import PhotosUI
import OSLog
import Models
import WidgetFeature

public protocol ScreenshotImporting {
    func screenshots(from source: PhotoSource) async throws -> [UIScreenshot]
}

/// Loads an array of `Screenshot`from different source types depending on the input `PhotoSource`
public struct ScreenshotImporter: ScreenshotImporting {
    private let logger = Logger(category: ScreenshotImporter.self)
    
    // MARK: - Initializer
    
    public init() { }
    
    // MARK: - Public
    
    /// Loads an array of `Screenshot`from different source types depending on the input `PhotoSource`
    public func screenshots(from source: PhotoSource) async throws -> [UIScreenshot] {
        switch source {
        case .photoPicker(let photosPickerItems):
            logger.info("Fetching images from the photos picker.")
            return try await photosPickerItems.loadUImages()
        case .photoAssetID(let url):
            let deepLinkManager = DeepLinkManager()
            let deepLink = try deepLinkManager.deepLink(from: url)
            let imageManager = ImageManager()
                        
            switch deepLink {
            case .latestScreenshot:
                logger.info("Fetching latest screenshot.")
                let screenshot = try await imageManager.latestScreenshot(from: url)
                logger.info("Successfully fetched latest screenshot.")
                return [screenshot]
            case .multipleScreenshots:
                logger.info("Fetching multiple screenshots.")
                let durationString = try deepLinkManager.deepLinkValue(from: url)
                let duration = Int(durationString)!
                let screenshots = try await imageManager.multipleScreenshots(within: duration)
                logger.info("Retrieved (\(screenshots.count, privacy: .public)) screenshots.")
                return screenshots
            }
        case .filePicker(let urls):
            let screenshots = try urls.compactMap { url in
                let accessing = url.startAccessingSecurityScopedResource()
                let data = try Data(contentsOf: url)
                let image = UIImage(data: data)
                
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
                
                return image
            }
            logger.info("Using file picker images (\(screenshots.count, privacy: .public)).")
            return screenshots
        case .dropItems(let items):
            logger.info("Using dropped photos (\(items.count, privacy: .public)).")
            return items.compactMap { UIImage(data: $0) }
        case .existingScreenshots(let existing):
            logger.info("Using existing screenshots (\(existing.count, privacy: .public)).")
            return existing
        case .controlCenter(let id):
            let imageManager = ImageManager()

            switch id {
            case 0:
                let screenshot = try await imageManager.latestScreenshot()
                return [screenshot]
            case 1:
                return try await imageManager.multipleScreenshots(within: 0)
            case 2:
                return try await imageManager.multipleScreenshots(within: 1)
            case 3:
                return try await imageManager.multipleScreenshots(within: 2)
            case 4:
                return try await imageManager.multipleScreenshots(within: 3)
            default:
                throw SBError.lowMemoryWarning
            }
        }
    }
}
