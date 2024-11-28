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

public protocol ScreenshotImporting: Sendable {
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
                let (screenshot, _) = try await imageManager.latestScreenshot(using: .url(url))
                logger.info("Successfully fetched latest screenshot.")
                return [screenshot]
            case .multipleScreenshots:
                logger.info("Fetching multiple screenshots.")
                let durationString = try deepLinkManager.deepLinkValue(from: url)
                guard
                    let duration = Int(durationString),
                    let option = DurationWidgetOption(rawValue: duration)
                else {
                    throw DeepLinkManager.DeepLinkManagerError.badDeepLinkURL
                }
                
                let screenshots = try await imageManager.multipleScreenshots(for: option)
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
                let (screenshot, _) = try await imageManager.latestScreenshot(using: .latest)
                return [screenshot]
            case 1...4:
                guard let option = DurationWidgetOption(rawValue: id - 1) else {
                    throw Error.invalidOption
                }
                
                return try await imageManager.multipleScreenshots(for: option)
            default:
                throw Error.invalidID
            }
        }
    }
    
    // MARK: - Errors
    
    public struct Error: LocalizedError {
        public let errorDescription: String?
        public let recoverySuggestion: String?
                
        public static let invalidOption = Self(
            errorDescription: "Invalid Option",
            recoverySuggestion: "The option that was passed in is invalid"
        )
        
        public static let invalidID = Self(
            errorDescription: "Invalid ID",
            recoverySuggestion: "The id that was passed in is invalid"
        )
    }
}
