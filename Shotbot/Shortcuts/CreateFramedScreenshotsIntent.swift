//
//  CreateFramedScreenshotsIntent.swift
//
//  Created by Richard Witherspoon on 4/19/23.
//

import SwiftUI
import AppIntents
import CollectionConcurrencyKit
import Models
import Persistence
import MediaManager
import OSLog
import SBFoundation

public struct CreateFramedScreenshotsIntent: AppIntent {
    static let intentClassName = "CreateFramedScreenshotsIntent"
    public static var title: LocalizedStringResource = "Create Framed Screenshots"
    static var description = IntentDescription("Creates framed screenshots with a device frame using the images passed in.")
    public static var isDiscoverable: Bool = true
    private let logger = Logger(category: CreateFramedScreenshotsIntent.self)
    
    public init() { }
    
    @Parameter(
        title: "Images",
        description: "The plain screenshots passed in that will be framed.",
        supportedTypeIdentifiers: ["public.image"],
        inputConnectionBehavior: .connectToPreviousIntentResult
    )
    var images: [IntentFile]
    
    @Parameter(
        title: "Save to files",
        description: "Will automatically save each image to the files app."
    )
    var saveToFiles: Bool
    
    @Parameter(
        title: "Save to photos",
        description: "Will automatically save each image to your photo library."
    )
    var saveToPhotos: Bool
    
    @Parameter(
        title: "Image Quality",
        description: "The quality of the screenshot.",
        default: .original
    )
    var imageQuality: ShortcutsImageQuality
    
    public static var parameterSummary: some ParameterSummary {
        Summary("Create screenshots from \(\.$images)") {
            \.$saveToFiles
            \.$saveToPhotos
            \.$imageQuality
        }
    }
    
    
    // MARK: - Functions
    
    public func perform() async throws -> some IntentResult & ReturnsValue<[IntentFile]> {
        let persistenceManager = PersistenceManager.shared
        
        guard persistenceManager.canSaveFramedScreenshot else {
            logger.error("pro subscription required to save screenshot")
            throw SBError.proSubscriptionRequired
        }
        
        let screenshots = try await images.asyncCompactMap { file -> IntentFile? in
            let url = try await createDeviceFrame(using: file.data)
                
            var file = IntentFile(fileURL: url, type: .image)
            file.removedOnCompletion = true
            
            return file
        }
        
        persistenceManager.deviceFrameCreations += screenshots.count
        
        logger.debug("returning CreateFramedScreenshotsIntent result")
        return .result(value: screenshots)
    }
    
    private func createDeviceFrame(using data: Data) async throws -> URL {
        guard let screenshot = PlatformImage(data: data) else {
            logger.error("Data could not be turned into a UIImage")
            throw SBError.unsupportedImage
        }
                
        guard let device = DeviceInfo.all().first(where: {$0.inputSize == screenshot.size}) else {
            logger.error("Could not find an image with width: \(screenshot.size.width, privacy: .public) and height: \(screenshot.size.height, privacy: .public).")
            throw SBError.unsupportedDevice
        }
        
        guard let image = device.framed(using: screenshot)?.scaled(to: imageQuality.value) else {
            logger.error("Could not frame image.")
            throw SBError.framing
        }
        
        guard let data = image.pngData() else {
            logger.error("PNG Data could not be obtained")
            throw SBError.noImageData
        }
        
        let path = "\(UUID().uuidString).png"
        let temporaryDirectoryURL = URL.temporaryDirectory.appending(path: path)
        
        try data.write(to: temporaryDirectoryURL)
        logger.info("Writing image data to \(path, privacy: .public).")
        
        if saveToFiles {
            do {
                try FileManager.default.copyToiCloudFiles(from: temporaryDirectoryURL)
                logger.info("Saving to iCloud.")
            } catch {
                logger.error("Error saving to iCloud: \(error.localizedDescription, privacy: .public).")
                throw error
            }
        }
        
        if saveToPhotos {
            do {
                try await PhotoLibraryManager.live.savePhoto(temporaryDirectoryURL)
                logger.info("Saving to Photo library.")
            } catch {
                logger.error("Error saving to photo library: \(error.localizedDescription, privacy: .public).")
                throw error
            }
        }
        
        return temporaryDirectoryURL
    }
}
