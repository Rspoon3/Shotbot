//
//  HomeViewModel.swift
//  Shot Bot
//
//  Created by Richard Witherspoon on 4/20/23.
//

import SwiftUI
import PhotosUI
import Models
import Persistence
import Purchases
import MediaManager
import StoreKit
import OSLog
import SBFoundation
import Photos
import CollectionConcurrencyKit
import WidgetFeature

@MainActor public final class HomeViewModel: ObservableObject {
    private var persistenceManager: any PersistenceManaging
    private let photoLibraryManager: PhotoLibraryManager
    private let purchaseManager: any PurchaseManaging
    private let fileManager: any FileManaging
    private var combinedImageTask: Task<Void, Never>?
    private var imageQuality: ImageQuality
    private(set) var imageResults = ImageResults()
    private let logger = Logger(category: HomeViewModel.self)
    @Published public var showPurchaseView = false
    @Published public var showAutoSaveToast = false
    @Published public var showCopyToast = false
    @Published public var showQuickSaveToast = false
    @Published public var showPhotosPicker = false
    @Published public var isLoading = false
    @Published public var imageSelections: [PhotosPickerItem] = []
    @Published public var viewState: ViewState = .individualPlaceholder
    @Published public var isImportingFile = false
    @Published public var showGridView: Bool
    @Published public var imageType: ImageType = .individual {
        didSet {
            imageTypeDidToggle()
        }
    }
    @Published public var error: Error? {
        didSet {
            guard error != nil else { return }
            isLoading = false
        }
    }
    
    var showLoadingSpinner: Bool {
        isLoading && viewState != .combinedPlaceholder
    }
    
    var toastText: String? {
        let files = persistenceManager.autoSaveToFiles
        let photos = persistenceManager.autoSaveToPhotos
        
        if files && photos {
            return "Saved to photos & files"
        } else if files {
            return "Saved to files"
        } else if photos {
            return "Saved to photos"
        } else {
            return nil
        }
    }
    
    var photoFilter: PHPickerFilter {
        persistenceManager.imageSelectionType.filter
    }
    
    var canShowClearButton: Bool {
        imageResults.hasImages
    }
    
    var viewTypeImageName: String? {
        guard imageResults.hasMultipleImages else { return nil }
        return persistenceManager.defaultHomeView == .grid ? "ellipsis.rectangle" : "square.grid.2x2"
    }
    
    // MARK: - Initializer
    
    public init(
        persistenceManager: any PersistenceManaging = PersistenceManager.shared,
        photoLibraryManager: PhotoLibraryManager = .live,
        purchaseManager: any PurchaseManaging = PurchaseManager.shared,
        fileManager: any FileManaging = FileManager.default
    ) {
        self.persistenceManager = persistenceManager
        self.photoLibraryManager = photoLibraryManager
        self.purchaseManager = purchaseManager
        self.fileManager = fileManager
        self.imageQuality = persistenceManager.imageQuality
        self.showGridView = persistenceManager.defaultHomeView == .grid
    }
    
    
    // MARK: - Private Helpers
    /// Updates `viewState` when `imageType` changes.
    ///
    /// Will wait for `combinedImageTask` if needed.
    private func imageTypeDidToggle() {
        switch imageType {
        case .individual:
            logger.notice("ImageType switched to individual.")
            
            if imageResults.hasImages {
                viewState = .individualImages(imageResults.individual)
                logger.notice("ViewState switched to individual images.")
            } else {
                viewState = .individualPlaceholder
                logger.notice("ViewState switched to individualPlaceholder.")
            }
        case .combined:
            logger.notice("ImageType switched to combined.")
            
            if let cachedImage = imageResults.combined {
                logger.notice("Using cached combined image.")
                viewState = .combinedImages(cachedImage)
            } else {
                logger.notice("ViewState switched to combined placeholder.")
                viewState = .combinedPlaceholder
                
                Task {
                    await combinedImageTask?.value
                    
                    guard let combined = imageResults.combined else {
                        logger.notice("ImageResults.combined is nil.")
                        throw SBError.unsupportedImage
                    }
                    
                    guard viewState == .combinedPlaceholder else {
                        logger.info("ViewState has changed- no need to switch view state.")
                        return
                    }
                    
                    viewState = .combinedImages(combined)
                    logger.notice("ViewState switched to combined images.")
                }
            }
        }
    }
    
    /// Asks the user to confirm deleting the selected photos from the photo library if this
    /// setting is enabled.
    private func autoDeleteScreenshotsIfNeeded() async {
        guard persistenceManager.autoDeleteScreenshots else { return }
        let ids = imageSelections.compactMap(\.itemIdentifier)
        try? await photoLibraryManager.delete(ids)
        logger.notice("Deleting \(ids.count, privacy: .public) images.")
    }
    
    /// Shows the `showAutoSaveToast` if the user has `autoSaveToFiles` or `autoSaveToPhotos` enabled
    ///
    /// Using a slight delay in order to make the UI less jarring
    private func autoSaveIndividualImagesIfNeeded() async {
        guard persistenceManager.autoSaveToFiles || persistenceManager.autoSaveToPhotos else { return }
        
        do {
            for result in imageResults.individual {
                if persistenceManager.autoSaveToFiles {
                    try fileManager.copyToiCloudFiles(from: result.url)
                    logger.info("Saving to iCloud.")
                }
                
                if persistenceManager.autoSaveToPhotos {
                    try await photoLibraryManager.savePhoto(result.url)
                    logger.info("Saving to Photo library.")
                }
            }
            
            try await Task.sleep(for: .seconds(0.75))
            showAutoSaveToast = true
            
            if toastText == nil {
                logger.fault("Toast text returned nil.")
            }
            
            try await Task.sleep(for: .seconds(0.75))
        } catch {
            logger.info("An autosave error occurred: \(error.localizedDescription, privacy: .public).")
            self.error = error
        }
    }
    
    /// Autosaves the combined image to photos and iCloud if the user has `autoSaveToFiles` and/or `autoSaveToPhotos` enabled
    private func autoSaveCombinedIfNeeded() async {
        guard persistenceManager.autoSaveToFiles || persistenceManager.autoSaveToPhotos else { return }
        guard let combinedURL = imageResults.combined?.url else { return }
        
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
            self.error = error
        }
    }
    
    /// Cancels and nils out `combinedImageTask`
    private func stopCombinedImageTask() {
        logger.debug("Stopping combined image task.")
        combinedImageTask?.cancel()
        combinedImageTask = nil
    }
    
    /// Combines images Horizontally with scaling to keep consistent spacing
    private func createCombinedImage(from images: [UIImage]) async throws -> ShareableImage {
        let imageQualityValue = imageQuality.value
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: SBError.noSelf)
                    return
                }
                
                self.logger.info("Starting combined image task.")
                
                defer {
                    self.logger.info("Ending combined image task.")
                }
                
                let imagesWidth = images.map(\.size.width).reduce(0, +)
                let resizedImages = images.map { image in
                    let widthScale = (image.size.width / imagesWidth)
                    let scale = max(widthScale, imageQualityValue)
                    let size = CGSize(
                        width: image.size.width * scale,
                        height: image.size.height * scale
                    )
                    return image.resized(to: size)
                }
                
                let combined = resizedImages.combineHorizontally()
                
                guard let data = combined.pngData() else {
                    self.logger.error("No combined image png data")
                    continuation.resume(throwing: SBError.noImageData)
                    return
                }
                
                let temporaryURL = URL.temporaryDirectory.appending(path: "Combined \(UUID().uuidString).png")
                
                do {
                    try data.write(to: temporaryURL)
                    self.logger.info("Saving combined data to temporary url.")
                    
                    let image = ShareableImage(framedScreenshot: combined, url: temporaryURL)
                    
                    continuation.resume(returning: image)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// If their are multiple image results, it will start the process of combining them horizontally
    private func combineDeviceFrames() async {
        guard imageResults.hasMultipleImages else { return }
        
        stopCombinedImageTask()
        
        combinedImageTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            
            imageResults.combined = try? await createCombinedImage(
                from: imageResults.individual.map(\.framedScreenshot)
            )
        }
        
        await combinedImageTask?.value
    }
    
    /// Loads an array of `Screenshot`from different source types depending on the input `PhotoSource`
    private func getScreenshots(from source: PhotoSource) async throws -> [UIScreenshot] {
        let screenshots: [UIScreenshot]
        
        switch source {
        case .photoPicker:
            logger.info("Fetching images from the photos picker.")
            screenshots = try await imageSelections.loadUImages()
        case .photoAssetID(let url):
            let deepLinkManager = DeepLinkManager()
            let deepLink = try deepLinkManager.deepLink(from: url)
            let imageManager = ImageManager()
                        
            switch deepLink {
            case .latestScreenshot:
                logger.info("Fetching latest screenshot.")
                let image = try await imageManager.latestScreenshot(from: url)
                screenshots = [image]
                logger.info("Successfully fetched latest screenshot.")
            case .multipleScreenshots:
                logger.info("Fetching multiple screenshots.")
                let images = try await imageManager.multipleScreenshots(from: url)
                screenshots = images
                logger.info("Retrieved (\(screenshots.count, privacy: .public)) screenshots.")
            }
        case .filePicker(let urls):
            screenshots = try urls.compactMap { url in
                let accessing = url.startAccessingSecurityScopedResource()
                let data = try Data(contentsOf: url)
                let image = UIImage(data: data)
                
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
                
                return image
            }
            logger.info("Using file picker images (\(screenshots.count, privacy: .public)).")
        case .dropItems(let items):
            logger.info("Using dropped photos (\(items.count, privacy: .public)).")
            screenshots = items.compactMap { UIImage(data: $0) }
        case .existingScreenshots(let existing):
            logger.info("Using existing screenshots (\(existing.count, privacy: .public)).")
            screenshots = existing
        }
        
        return screenshots
    }
    
    /// Updates `imageResults` `individual`property and counts up `PersistenceManaging.deviceFrameCreations`
    private func updateImageResultsIndividualImages(using screenshots: [UIImage]) async throws {
        var shareableImages = [ShareableImage]()
        
        for (i, screenshot) in screenshots.enumerated() {
            let shareableImage = try await createDeviceFrame(using: screenshot, count: i)
            
            shareableImages.append(shareableImage)
            persistenceManager.deviceFrameCreations += 1
        }
        
        logger.debug("Setting imageResults.individual with \(shareableImages.count, privacy: .public) items.")
        imageResults.individual = shareableImages
        showGridView = persistenceManager.defaultHomeView == .grid && imageResults.hasMultipleImages
    }
    
    /// Starts the image pipeline using the passed in screenshots
    private func processSelectedPhotos(source: PhotoSource) async throws {
        // Loading
        logger.info("Starting processing selected photos")
        isLoading = true
        defer {
            logger.info("Ending processing selected photos.")
            
            if imageType == .individual {
                isLoading = false
            }
        }
        
        // Prep
        stopCombinedImageTask()
        
        let screenshots = try await getScreenshots(from: source)
        
        guard !screenshots.isEmpty else { return }
        
        if persistenceManager.defaultHomeTab == .combined,
           screenshots.count > 1,
           imageType == .individual {
            imageType = .combined
        }
        
        // ImageResults updating
        imageResults.originalScreenshots = screenshots
        try await updateImageResultsIndividualImages(using: screenshots)
        
        // Reset view
        if imageType == .individual {
            logger.info("Setting viewState to individualImages and ending isLoading.")
            viewState = .individualImages(imageResults.individual)
            isLoading = false
        }
        
        guard imageResults.hasImages else {
            logger.fault("Processing selected photos returning early because imageResults has no image.")
            return
        }
        
        Task(priority: .userInitiated) {
            await combineDeviceFrames()
            await autoSaveCombinedIfNeeded()
            
            if imageType == .combined {
                isLoading = false
                
                guard let combined = imageResults.combined else {
                    logger.fault("Processing selected photos returning early because combined image results has no image.")
                    throw SBError.unsupportedImage
                }
                
                logger.fault("Setting viewState to combinedImages")
                viewState = .combinedImages(combined)
            }
            
            // Post FramedScreenshot generation
            await autoSaveIndividualImagesIfNeeded()
            await autoDeleteScreenshotsIfNeeded()
            askForAReview()
        }
    }
    
    /// Asks the user for a review
    private func askForAReview() {
        let deviceFrameCreations = persistenceManager.deviceFrameCreations
        let numberOfActivations = persistenceManager.numberOfActivations
        
        guard deviceFrameCreations > 3 && numberOfActivations > 3 else {
            logger.debug("Review prompt criteria not met. DeviceFrameCreations: \(deviceFrameCreations, privacy: .public), numberOfActivations: \(numberOfActivations, privacy: .public).")
            return
        }
        
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            logger.fault("Could not find UIWindowScene to ask for review")
            return
        }
        
        if let date = persistenceManager.lastReviewPromptDate {
            guard date >= Date.now.adding(days: 3) else {
                logger.debug("Last review prompt date to recent: \(date, privacy: .public).")
                return
            }
        }
        
        SKStoreReviewController.requestReview(in: scene)
        
        persistenceManager.lastReviewPromptDate = .now
        logger.log("Prompting the user for a review")
    }
    
    // MARK: - Public
    
    /// Updates the `defaultHomeView` in the persistence manger and then updates
    /// `showGridView`.
    public func toggleIndividualViewType() {
        switch persistenceManager.defaultHomeView {
        case .grid:
            persistenceManager.defaultHomeView = .tabbed
        case .tabbed:
            persistenceManager.defaultHomeView = .grid
        }
        
        showGridView = persistenceManager.defaultHomeView == .grid && imageResults.hasMultipleImages
    }
    
    /// Starts the image pipeline with `dropItems` as the photo source
    public func didDropItem(_ items: [Data]) async {
        do {
            try await processSelectedPhotos(source: .dropItems(items))
        } catch {
            self.error = error
        }
    }
    
    public func didOpenViaDeepLink(_ url: URL) {
        Task {
            try await processSelectedPhotos(source: .photoAssetID(url))
        }
    }
    
    /// Shows the user the photo picker and then uses their selection to kick off the image pipeline
    /// using `photoPicker` as the image source
    public func imageSelectionsDidChange() async {
        do {
            try await processSelectedPhotos(source: .photoPicker)
        } catch {
            self.error = error
        }
    }
    
    /// If not loading, show the photo picker.
    public func selectPhotos() {
        guard persistenceManager.canSaveFramedScreenshot else {
            showPurchaseView = true
            return
        }
        
        guard !isLoading else {
            logger.fault("Trying to select photos while in a loading state.")
            return
        }
        
        showPhotosPicker = true
    }
    
    /// Creates a `ShareableImage` from a `UIScreenshot`
    ///
    /// Will auto save to files or photos if necessary
    public func createDeviceFrame(using screenshot: UIScreenshot, count: Int) async throws -> ShareableImage {
        let framedScreenshot = try screenshot.framedScreenshot(quality: persistenceManager.imageQuality)
        let path = "Framed Screenshot \(count)_\(UUID()).png"
        let temporaryURL = URL.temporaryDirectory.appending(path: path)
        
        guard let data = framedScreenshot.pngData() else {
            logger.error("Could not get png data for framedScreenshot.")
            throw SBError.noImageData
        }
        
        try data.write(to: temporaryURL)
        logger.info("Writing \(path, privacy: .public) to temporary url.")
        
        return ShareableImage(
            framedScreenshot: framedScreenshot,
            url: temporaryURL
        )
    }
    
    /// Clears all images when the user backgrounds the app, if the setting is enabled.
    public func clearImagesOnAppBackground() {
        guard persistenceManager.clearImagesOnAppBackground else { return }
        logger.info("Clearing images on app background")
        
        clearContent()
    }
    
    /// Clears all images and reverts the viewState back to individual placeholder
    public func clearContent() {
        logger.info("Clearing all content")
        
        stopCombinedImageTask()
        imageResults.removeAll()
        imageSelections.removeAll()
        viewState = .individualPlaceholder
        imageType = .individual
    }
    
    /// Checks if the users has changed image quality. If so, the original screenshots are rerun
    /// though the pipeline to create new framed screenshots based on the new image quality.
    public func changeImageQualityIfNeeded() async {
        guard imageQuality != persistenceManager.imageQuality else { return }
        
        logger.info("Re-running pipeline due to image quality change.")
        
        imageQuality = persistenceManager.imageQuality
        
        await combinedImageTask?.value
        
        try? await processSelectedPhotos(
            source: .existingScreenshots(imageResults.originalScreenshots)
        )
    }
    
    /// Copies a framed screenshot to the clipboard
    public func copy(_ image: UIFramedScreenshot) {
        guard persistenceManager.canSaveFramedScreenshot else {
            showPurchaseView = true
            return
        }
        
        UIPasteboard.general.image = image
        showCopyToast = true
        logger.debug("Copying image.")
    }
    
    /// Saves a framed screenshot to the users photo library
    public func saveToPhotos(_ image: UIFramedScreenshot) async {
        guard persistenceManager.canSaveFramedScreenshot else {
            showPurchaseView = true
            return
        }
        
        do {
            try await photoLibraryManager.save(image)
            showQuickSaveToast = true
            logger.debug("Manually saving image to photo library.")
        } catch {
            logger.error("Error manually saving image to photo library: \(error.localizedDescription, privacy: .public).")
            self.error = error
        }
    }
    
    /// Saves a framed screenshot to iCloud using the url
    public func saveToiCloud(_ url: URL) {
        guard persistenceManager.canSaveFramedScreenshot else {
            showPurchaseView = true
            return
        }
        
        do {
            try fileManager.copyToiCloudFiles(from: url)
            showQuickSaveToast = true
            logger.debug("Manually saving image to iCloud.")
        } catch {
            logger.error("Error manually saving image to iCloud: \(error.localizedDescription, privacy: .public).")
            self.error = error
        }
    }
    
    /// Requests photo library addition authorization
    public func requestPhotoLibraryAdditionAuthorization() async {
        await photoLibraryManager.requestPhotoLibraryAdditionAuthorization()
        
        let status = photoLibraryManager.photoAdditionStatus.title
        logger.info("Finished requesting photo library addition authorization. Status: \(status, privacy: .public).")
    }
    
    /// Starts the photo selection process using imported files from the Files app
    public func fileImportCompletion(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task {
                do {
                    try await processSelectedPhotos(
                        source: .filePicker(urls)
                    )
                } catch {
                    self.error = error
                }
            }
        case .failure(let error):
            logger.error("File import error: \(error.localizedDescription, privacy: .public).")
            self.error = error
        }
    }
}
