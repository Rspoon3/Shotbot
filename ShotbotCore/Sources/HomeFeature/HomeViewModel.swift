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


@MainActor public final class HomeViewModel: ObservableObject {
    let alertTitle = "Something went wrong."
    let alertMessage = "Please make sure you are selecting a screenshot."
    private var persistenceManager: any PersistenceManaging
    private let photoLibraryManager: any PhotoLibraryManaging
    private let purchaseManager: any PurchaseManaging
    private let fileManager: any FileManaging
    private var combinedImageTask: Task<Void, Never>?
    private var imageQuality: ImageQuality
    private(set) var imageResults = ImageResults()
    @Published public var showPurchaseView = false
    @Published public var showAutoSaveToast = false
    @Published public var showCopyToast = false
    @Published public var showQuickSaveToast = false
    @Published public var showPhotosPicker = false
    @Published public var showAlert = false
    @Published public var isLoading = false
    @Published public var imageSelections: [PhotosPickerItem] = []
    @Published public var viewState: ViewState = .individualPlaceholder
    @Published public var imageType: ImageType = .individual {
        didSet {
            imageTypeDidToggle()
        }
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
    
    // MARK: - Initializer
    
    public init(
        persistenceManager: any PersistenceManaging = PersistenceManager.shared,
        photoLibraryManager: any PhotoLibraryManaging = PhotoLibraryManager.shared,
        purchaseManager: any PurchaseManaging = PurchaseManager.shared,
        fileManager: any FileManaging = FileManager.default
    ) {
        self.persistenceManager = persistenceManager
        self.photoLibraryManager = photoLibraryManager
        self.purchaseManager = purchaseManager
        self.fileManager = fileManager
        self.imageQuality = persistenceManager.imageQuality
    }
    
    
    // MARK: - Private Helpers
    
    /// Updates `viewState` when `imageType` changes.
    ///
    /// Will wait for `combinedImageTask` if needed.
    private func imageTypeDidToggle() {
        switch imageType {
        case .individual:
            if imageResults.hasImages {
                viewState = .individualImages(imageResults.individual)
            } else {
                viewState = .individualPlaceholder
            }
        case .combined:
            if let cachedImage = imageResults.combined {
                viewState = .combinedImages(cachedImage)
            } else {
                viewState = .combinedPlaceholder
                
                Task {
                    await combinedImageTask?.value
                    
                    guard
                        let combined = imageResults.combined,
                        viewState == .combinedPlaceholder
                    else {
                        throw SBError.noImage
                    }
                    
                    viewState = .combinedImages(combined)
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
    }
    
    /// Shows the `showAutoSaveToast` if the user has `autoSaveToFiles` or `autoSaveToPhotos` enabled
    ///
    /// Using a slight delay in order to make the UI less jarring
    private func showAutoSaveToastIfNeeded() async {
        guard persistenceManager.autoSaveToFiles || persistenceManager.autoSaveToPhotos else { return }
        try? await Task.sleep(for: .seconds(0.75))
        showAutoSaveToast = true
        try? await Task.sleep(for: .seconds(0.75))
    }
    
    /// Cancels and nils out `combinedImageTask`
    private func stopCombinedImageTask() {
        combinedImageTask?.cancel()
        combinedImageTask = nil
    }
    
    /// Combines images Horizontally with scaling to keep consistent spacing
    ///
    /// nonisolated in order to run on a background thread and not disrupt the main thread
    ///
    // TODO: This can be refactored and moved to an extension
    nonisolated private func createCombinedImage(from images: [UIImage]) async throws {
        try await Task {
            let imagesWidth = images.map(\.size.width).reduce(0, +)
            
            let resizedImages = images.map { image in
                let scale = (image.size.width / imagesWidth)
                let size = CGSize(
                    width: image.size.width * scale,
                    height: image.size.height * scale
                )
                return image.resized(to: size)
            }
            
            let combined = resizedImages.combineHorizontally()
            
            guard let data = combined.pngData() else {
                throw SBError.noData
            }
            
            let temporaryURL = URL.temporaryDirectory.appending(path: "combined.png")
            
            try data.write(to: temporaryURL)
            
            await MainActor.run {
                imageResults.combined = ShareableImage(framedScreenshot: combined, url: temporaryURL)
            }
        }.value
    }
    
    /// If their are multiple image results, it will start the process of combining them horizontally
    private func combineDeviceFrames() {
        guard imageResults.hasMultipleImages else { return }
        
        stopCombinedImageTask()
        
        combinedImageTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            try? await createCombinedImage(
                from: imageResults.individual.map(\.framedScreenshot)
            )
        }
    }
    
    /// Loads an array of `Screenshot`from different source types depending on the input `PhotoSource`
    private func getScreenshots(from source: PhotoSource) async throws -> [UIScreenshot] {
        let screenshots: [UIScreenshot]
        
        switch source {
        case .photoPicker:
            screenshots = try await imageSelections.loadUImages()
        case .dropItems(let items):
            screenshots = items.compactMap { UIImage(data: $0) }
        case .existingScreenshots(let existing):
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
        
        imageResults.individual = shareableImages
    }
    
    /// Starts the image pipeline using the passed in screenshots
    private func processSelectedPhotos(
        resetView: Bool,
        source: PhotoSource
    ) async throws {
        // Loading
        isLoading = true
        defer { isLoading = false }
       
        // Prep
        stopCombinedImageTask()
        
        let screenshots = try await getScreenshots(from: source)
        
        guard !screenshots.isEmpty else { return }
        
        // Update view
        if resetView {
            viewState = .individualPlaceholder
            imageType = .individual
            imageResults.removeAll()
        }
        
        // ImageResults updating
        imageResults.originalScreenshots = screenshots
        try await updateImageResultsIndividualImages(using: screenshots)
        
        // Reset view
        if resetView || imageType == .individual {
            viewState = .individualImages(imageResults.individual)
            isLoading = false
        }
        
        guard imageResults.hasImages else { return }
        
        combineDeviceFrames()
        
        if imageType == .combined {
            await combinedImageTask?.value
            
            guard let combined = imageResults.combined else {
                throw SBError.noImage
            }
            
            viewState = .combinedImages(combined)
        }
        
        // Post FramedScreenshot generation
        await showAutoSaveToastIfNeeded()
        await autoDeleteScreenshotsIfNeeded()
        askForAReview()
    }
    
    /// Asks the user for a review
    private func askForAReview() {
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }
          
        SKStoreReviewController.requestReview(in: scene)
    }
    
    // MARK: - Public
    
    /// Starts the image pipeline with `dropItems` as the photo source
    public func didDropItem(_ items: [Data]) async {
        do {
            try await processSelectedPhotos(resetView: false, source: .dropItems(items))
        } catch {
            showAlert = true
        }
    }
    
    /// Shows the user the photo picker and then uses their selection to kick off the image pipeline
    /// using `photoPicker` as the image source
    public func imageSelectionsDidChange() async {
        do {
            try await processSelectedPhotos(resetView: true, source: .photoPicker)
        } catch {
            showAlert = true
        }
    }
    
    /// If not loading, show the photo picker.
    public func selectPhotos() {
        guard persistenceManager.canSaveFramedScreenshot else {
            showPurchaseView = true
            return
        }
        
        guard !isLoading else { return }
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
            throw SBError.noData
        }
        
        try data.write(to: temporaryURL)
        
        if persistenceManager.autoSaveToFiles {
            let destination = URL.documentsDirectory.appending(path: path)
            try fileManager.copyItem(at: temporaryURL, to: destination)
        }
        
        if persistenceManager.autoSaveToPhotos {
            try await photoLibraryManager.savePhoto(at: temporaryURL)
        }
        
        return ShareableImage(
            framedScreenshot: framedScreenshot,
            url: temporaryURL
        )
    }
    
    /// Clears all images when the user backgrounds the app, if the setting is enabled.
    public func clearImagesOnAppBackground() {
        guard persistenceManager.clearImagesOnAppBackground else { return }
        
        stopCombinedImageTask()
        viewState = .individualPlaceholder
        imageType = .individual
        imageResults.removeAll()
        imageSelections.removeAll()
    }
    
    /// Checks if the users has changed image quality. If so, the original screenshots are rerun
    /// though the pipeline to create new framed screenshots based on the new image quality.
    public func changeImageQualityIfNeeded() async {
        guard imageQuality != persistenceManager.imageQuality else { return }
        imageQuality = persistenceManager.imageQuality
        
        await combinedImageTask?.value
        
        try? await processSelectedPhotos(
            resetView: false,
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
    }
    
    /// Saves a framed screenshot to the users photo library
    public func save(_ image: UIFramedScreenshot) async {
        guard persistenceManager.canSaveFramedScreenshot else {
            showPurchaseView = true
            return
        }
        
        try? await photoLibraryManager.save(image)
        showQuickSaveToast = true
    }
}
