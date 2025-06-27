//
//  AutoCRUDManager.swift
//  ShotbotCore
//
//  Created by Richard Witherspoon on 7/24/24.
//

import SwiftUI
import Persistence
import OSLog
import MediaManager
import SBFoundation
import PhotosUI
import Models
import SwiftTools

@MainActor
public protocol AutoCRUDManaging: Sendable {
    func autoSaveIndividualImagesIfNeeded(
        using shareableImages: [ShareableImage],
        autoSave: @escaping ()-> Void
    ) async throws
    
    func autoSaveCombinedIfNeeded(using combinedURL: URL?) async throws
    func autoDeleteScreenshotsIfNeeded(items: [PhotosPickerItem]) async
}

/// An object thats responsible for auto saving individual and combined images as
/// well as auto deleting screenshots. All actions are only applicable with
/// certain user settings enabled
@MainActor
public struct AutoCRUDManager: AutoCRUDManaging {
    private var persistenceManager: any PersistenceManaging
    private let logger = Logger(category: AutoCRUDManager.self)
    private let clock: any Clock<Duration>
    private let photoLibraryManager: PhotoLibraryManager
    private let fileManager: any FileManaging
    
    var canAutoSave: Bool {
        persistenceManager.autoSaveToFiles || persistenceManager.autoSaveToPhotos
    }
        
    // MARK: - Initializer
    
    public init(
        persistenceManager: any PersistenceManaging = PersistenceManager.shared,
        clock: any Clock<Duration> = ContinuousClock(),
        photoLibraryManager: PhotoLibraryManager = .live,
        fileManager: any FileManaging = FileManager.default
    ) {
        self.persistenceManager = persistenceManager
        self.clock = clock
        self.photoLibraryManager = photoLibraryManager
        self.fileManager = fileManager
    }
    
    /// Shows the `showAutoSaveToast` if the user has `autoSaveToFiles` or `autoSaveToPhotos` enabled
    ///
    /// Using a slight delay in order to make the UI less jarring
    public func autoSaveIndividualImagesIfNeeded(
        using shareableImages: [ShareableImage],
        autoSave: @escaping ()-> Void
    ) async throws {
        guard canAutoSave else { return }
        
        do {
            for shareableImage in shareableImages {
                if persistenceManager.autoSaveToFiles {
                    try fileManager.copyToiCloudFiles(from: shareableImage.url)
                    logger.info("Saving to iCloud.")
                }
                
                if persistenceManager.autoSaveToPhotos {
                    try await photoLibraryManager.savePhoto(shareableImage.url)
                    logger.info("Saving to Photo library.")
                }
            }
            
            try await clock.sleep(for: .seconds(0.75))
            autoSave()
            try await clock.sleep(for: .seconds(0.75))
        } catch {
            logger.info("An autosave error occurred: \(error.localizedDescription, privacy: .public).")
            throw error
        }
    }
    
    /// Autosaves the combined image to photos and iCloud if the user has `autoSaveToFiles` and/or `autoSaveToPhotos` enabled
    public func autoSaveCombinedIfNeeded(using combinedURL: URL?) async throws {
        guard let combinedURL, canAutoSave else {
            return
        }
        
        do {
            if persistenceManager.autoSaveToFiles {
                try fileManager.copyToiCloudFiles(from: combinedURL)
                logger.info("Saving combined image to iCloud.")
            }
            
            if persistenceManager.autoSaveToPhotos {
                try await photoLibraryManager.savePhoto(combinedURL)
                logger.info("Saving combined image to Photo library.")
            }
        } catch {
            logger.info("An autosave error occurred for the combined image: \(error.localizedDescription, privacy: .public).")
            throw error
        }
    }
    
    /// Asks the user to confirm deleting the selected photos from the photo library if this
    /// setting is enabled.
    public func autoDeleteScreenshotsIfNeeded(items: [PhotosPickerItem]) async {
        guard persistenceManager.autoDeleteScreenshots else { return }
        let ids = items.compactMap(\.itemIdentifier)
        try? await photoLibraryManager.delete(ids)
        logger.notice("Deleting \(ids.count, privacy: .public) images.")
    }
}
