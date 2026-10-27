//
//  HomeViewModel.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 4/20/23.
//

import SwiftUI
import PhotosUI
import AVFoundation
import UniformTypeIdentifiers
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
import Combine
import CreateCombinedImageFeature
import SwiftTools

@MainActor public final class HomeViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private var persistenceManager: any PersistenceManaging
    private let photoLibraryManager: PhotoLibraryManager
    private let fileManager: any FileManaging
    private let imageCombiner: any ImageCombining
    private let reviewManager: any ReviewManaging
    private let autoCRUDManager: any AutoCRUDManaging
    private var combinedImageTask: Task<Void, Never>?
    private let screenshotImporter: any ScreenshotImporting
    private let notificationCenter: any NotificationCenterProtocol
    private var imageQuality: ImageQuality
    private let eligibilityUseCase = FramedScreenshotEligibilityUseCase()
    private let logger = Logger(category: HomeViewModel.self)
    private(set) var imageResults = ImageResults()
    @Published public var showPurchaseView = false
    @Published public var showCopyToast = false
    @Published public var showAutoSaveToast = false
    @Published public var showQuickSaveToast = false
    @Published public var showPhotosPicker = false
    @Published public var isLoading = false
    @Published public var imageSelections: [PhotosPickerItem] = []
    @Published public var viewState: ViewState = .individualPlaceholder
    /// The framed screen recording being shown, if the user picked a video instead of screenshots.
    @Published public private(set) var framedVideo: FramedVideo?
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
    /// The devices in the current screenshots whose frame comes in more than one color or view, for the toolbar menu.
    @Published public private(set) var styleOptions: [DeviceStyleOption] = []
    @Published public var showDeviceDisambiguation = false
    @Published public var ambiguousDeviceOptions: [DeviceInfo] = []
    @Published public var disambiguationScreenshot: UIImage?
    private var disambiguationContinuation: CheckedContinuation<DeviceInfo, Never>?
    
    var showLoadingSpinner: Bool {
        isLoading && viewState != .combinedPlaceholder
    }
    
    var toastText: String? {
        let files = persistenceManager.autoSaveFilesOption
        let photos = persistenceManager.autoSavePhotosOption

        if files != .none && photos != .none {
            return "Saved to photos & files"
        } else if files != .none {
            return "Saved to files"
        } else if photos != .none {
            return "Saved to photos"
        } else {
            return nil
        }
    }
    
    var photoFilter: PHPickerFilter {
        .any(of: [persistenceManager.imageSelectionType.filter, .videos])
    }
    
    var canShowClearButton: Bool {
        imageResults.hasImages || framedVideo != nil
    }
    
    var viewTypeImageName: String? {
        guard imageResults.hasMultipleImages else { return nil }
        return persistenceManager.defaultHomeView == .grid ? "ellipsis.rectangle" : "square.grid.2x2"
    }
    
    // MARK: - Initializer
    
    public init(
        persistenceManager: any PersistenceManaging = PersistenceManager.shared,
        photoLibraryManager: PhotoLibraryManager = .live,
        fileManager: any FileManaging = FileManager.default,
        notificationCenter: any NotificationCenterProtocol = NotificationCenter.default,
        screenshotImporter: any ScreenshotImporting = ScreenshotImporter(),
        reviewManager: any ReviewManaging = ReviewManager(),
        imageCombiner: any ImageCombining = ImageCombiner(),
        autoCRUDManager: any AutoCRUDManaging = AutoCRUDManager()
    ) {
        self.persistenceManager = persistenceManager
        self.photoLibraryManager = photoLibraryManager
        self.fileManager = fileManager
        self.reviewManager = reviewManager
        self.screenshotImporter = screenshotImporter
        self.imageCombiner = imageCombiner
        self.autoCRUDManager = autoCRUDManager
        self.imageQuality = persistenceManager.imageQuality
        self.showGridView = persistenceManager.defaultHomeView == .grid
        self.notificationCenter = notificationCenter
        
        subscribeToNotificationCenterPublishers()
    }
    
    
    // MARK: - Private Helpers
    
    /// Subscribes to notification center publishers such as memory warnings.
    private func subscribeToNotificationCenterPublishers() {
        notificationCenter.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.error = SBError.lowMemoryWarning
                self?.logger.warning("Memory warning hit")
            }.store(in: &cancellables)
    }
    
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
    
    /// Cancels and nils out `combinedImageTask`
    private func stopCombinedImageTask() {
        logger.debug("Stopping combined image task.")
        combinedImageTask?.cancel()
        combinedImageTask = nil
    }
    
    /// If their are multiple image results, it will start the process of combining them horizontally
    private func combineDeviceFrames() async {
        guard imageResults.hasMultipleImages else { return }
        
        stopCombinedImageTask()
        
        combinedImageTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            
            imageResults.combined = try? await imageCombiner.createCombinedImage(
                from: imageResults.individual.map(\.framedScreenshot),
                imageQuality: imageQuality.value
            )
        }
        
        await combinedImageTask?.value
    }
    
    /// Updates `imageResults` `individual`property and counts up `PersistenceManaging.deviceFrameCreations`
    private func updateImageResultsIndividualImages(using screenshots: [UIImage]) async throws {
        var shareableImages = [ShareableImage]()
        var devices = [DeviceInfo]()
        
        for (i, screenshot) in screenshots.enumerated() {
            let (shareableImage, device) = try await createDeviceFrame(using: screenshot, count: i)
            
            shareableImages.append(shareableImage)
            devices.append(device)
            persistenceManager.deviceFrameCreations += 1
        }
        
        logger.debug("Setting imageResults.individual with \(shareableImages.count, privacy: .public) items.")
        imageResults.individual = shareableImages
        imageResults.devices = devices
        refreshStyleOptions()
        showGridView = persistenceManager.defaultHomeView == .grid && imageResults.hasMultipleImages
    }
    
    /// Copies images to the pasteboard based on `autoCopyOption`, independent of the view type.
    private func copyAutomatically() {
        switch persistenceManager.autoCopyOption {
        case .none:
            break
        case .individual:
            let images = imageResults.individual.map(\.framedScreenshot)
            copy(images)
        case .combined:
            if let combined = imageResults.combined {
                copy(combined.framedScreenshot)
            }
        case .all:
            // Copy all available images (combined + individual)
            var allImages: [UIFramedScreenshot] = []
            if let combined = imageResults.combined {
                allImages.append(combined.framedScreenshot)
            }
            allImages.append(contentsOf: imageResults.individual.map(\.framedScreenshot))
            copy(allImages)
        }
    }
    
    /// Runs the user's auto save and auto copy settings on the current images.
    ///
    /// - Parameter images: The individual images to auto save. Defaults to all of them. Pass only the ones that changed
    ///   after a re-frame, or none after swapping places, so unchanged images are not saved a second time.
    private func runAutoActions(savingIndividualImages images: [ShareableImage]? = nil) async {
        let individualImages = images ?? imageResults.individual
        
        try? await autoCRUDManager.autoSaveCombinedIfNeeded(using: imageResults.combined?.url)
        copyAutomatically()
        
        if !individualImages.isEmpty {
            try? await autoCRUDManager.autoSaveIndividualImagesIfNeeded(using: individualImages) { [weak self] in
                DispatchQueue.main.async {
                    self?.showAutoSaveToast = true
                }
            }
        } else if savesCombinedImage {
            showAutoSaveToast = true
        }
    }
    
    /// Whether the user's auto save settings save the combined image to files or photos.
    private var savesCombinedImage: Bool {
        guard imageResults.combined != nil else { return false }
        
        let options: [AutoActionOption] = [persistenceManager.autoSaveFilesOption, persistenceManager.autoSavePhotosOption]
        
        return options.contains { $0 == .combined || $0 == .all }
    }
    
    /// Starts the image pipeline using the passed in screenshots
    private func processSelectedPhotos(source: PhotoSource) async throws {
        // Subscription Check
        let screenshotCount: Int
        
        if let itemCount = source.itemCount {
            screenshotCount = itemCount
        } else {
            screenshotCount = try await screenshotImporter.screenshots(from: source).count
        }
        
        let reason = await eligibilityUseCase.canSaveFramedScreenshot(screenshotCount: screenshotCount)
        
        guard reason.canSave else {
            showPurchaseView = true
            return
        }
        
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
        clearTemporaryDirectory()
        stopCombinedImageTask()
        framedVideo = nil
        
        let screenshots = try await screenshotImporter.screenshots(from: source)
        
        guard !screenshots.isEmpty else { return }
        
        if screenshots.count == 1, imageType == .combined {
            imageType = .individual
        } else if persistenceManager.defaultHomeTab == .combined, screenshots.count > 1, imageType == .individual {
            imageType = .combined
        }
        
        // ImageResults updating
        imageResults.originalScreenshots = screenshots
        
        if case .existingScreenshots = source, imageResults.overrides.count == screenshots.count {
            // The same screenshots again, such as after changing image quality, keep their own choices.
        } else {
            imageResults.overrides = Array(repeating: StyleOverride(), count: screenshots.count)
        }
        
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
            try? await autoCRUDManager.autoSaveCombinedIfNeeded(using: imageResults.combined?.url)
            
            copyAutomatically()

            switch imageType {
            case .combined:
                isLoading = false

                guard let combined = imageResults.combined else {
                    logger.fault("Processing selected photos returning early because combined image results has no image.")
                    throw SBError.unsupportedImage
                }

                logger.fault("Setting viewState to combinedImages")
                viewState = .combinedImages(combined)
            case .individual:
                break
            }
            
            // Post FramedScreenshot generation
            try? await autoCRUDManager.autoSaveIndividualImagesIfNeeded(using: imageResults.individual) { [weak self] in
                DispatchQueue.main.async {
                    self?.showAutoSaveToast = true
                }
            }
            await autoCRUDManager.autoDeleteScreenshotsIfNeeded(items: imageSelections)
            reviewManager.askForAReview()
            
            // Consume from rewards if needed
            if let amount = reason.rewardedScreenShotsCount {
                do {
                    try await eligibilityUseCase.consumeExtraScreenshot(amount: amount)
                    logger.info("Consumed \(amount, privacy: .public) extra screenshot(s).")
                } catch {
                    logger.error("Failed to consume \(amount, privacy: .public) extra screenshot(s): \(error.localizedDescription, privacy: .public).")
                }
            }
        }
    }
    
    /// Frames a screen recording and shows it in place of any screenshots.
    ///
    /// The device is matched from the video's size, asking the user when more than one fits, and uses the color and
    /// view last picked for it. The result is saved automatically when the user's auto save settings call for it.
    /// - Parameter loadSource: Copies the video into the temporary directory and returns the copy's URL. It runs after
    ///   the temporary directory is cleared, so the copy isn't deleted.
    private func processVideo(loadSource: () async throws -> URL?) async throws {
        let reason = await eligibilityUseCase.canSaveFramedScreenshot(screenshotCount: 1)
        
        guard reason.canSave else {
            showPurchaseView = true
            return
        }
        
        logger.info("Starting processing a video.")
        isLoading = true
        defer { isLoading = false }
        
        clearTemporaryDirectory()
        stopCombinedImageTask()
        imageResults.removeAll()
        styleOptions = []
        framedVideo = nil
        viewState = .individualPlaceholder
        
        guard let sourceURL = try await loadSource() else { throw SBError.unsupportedImage }
        
        let poster = try await VideoFramer.posterImage(ofVideoAt: sourceURL)
        
        guard let resolved = await resolveDevice(for: poster) else {
            throw SBError.unsupportedImage
        }
        
        let device = persistenceManager.applyingPreferredStyle(to: resolved)
        let outputURL = URL.temporaryDirectory.appending(path: "Framed Video \(UUID()).mp4")
        
        try await VideoFramer().frame(videoAt: sourceURL, in: device, to: outputURL)
        try? fileManager.removeItem(at: sourceURL)
        
        persistenceManager.deviceFrameCreations += 1
        framedVideo = FramedVideo(url: outputURL, device: device)
        
        if (try? await autoCRUDManager.autoSaveVideoIfNeeded(using: outputURL)) == true {
            showAutoSaveToast = true
        }
        
        reviewManager.askForAReview()
    }
    
    /// Copies a file the user picked in the Files app into the temporary directory.
    private static func copyToTemporaryDirectory(_ url: URL) throws -> URL {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
        
        let copy = URL.temporaryDirectory.appending(path: "Source Video \(UUID()).\(url.pathExtension)")
        try FileManager.default.copyItem(at: url, to: copy)
        return copy
    }
    
    /// Resolves the correct `DeviceInfo` for a screenshot, prompting the user when ambiguous.
    ///
    /// Checks the cached preference first. If no preference exists and the match is
    /// ambiguous, presents a confirmation dialog and awaits the user's selection.
    private func resolveDevice(for screenshot: UIImage) async -> DeviceInfo? {
        let screenshotSize = screenshot.size
        let result = DeviceInfo.match(for: screenshotSize)

        switch result {
        case .exact(let device):
            return device
        case .none:
            return nil
        case .ambiguous(let options):
            if !persistenceManager.alwaysAskDeviceFrame,
               let cached = persistenceManager.preferredDeviceFrame(for: screenshotSize),
               let device = options.first(where: { $0.deviceFrame == cached }) {
                return device
            }

            ambiguousDeviceOptions = options
            disambiguationScreenshot = screenshot
            showDeviceDisambiguation = true

            let chosen = await withCheckedContinuation { continuation in
                disambiguationContinuation = continuation
            }

            persistenceManager.setPreferredDeviceFrame(chosen.deviceFrame, for: screenshotSize)
            return chosen
        }
    }

    /// Called by the disambiguation dialog when the user selects a device.
    public func didSelectDisambiguatedDevice(_ device: DeviceInfo) {
        disambiguationContinuation?.resume(returning: device)
        disambiguationContinuation = nil
        disambiguationScreenshot = nil
        showDeviceDisambiguation = false
    }

    /// Frames a screenshot and returns the image along with the device it was framed with.
    ///
    /// The device uses the color the user last picked for it. Will auto save to files or photos if necessary.
    private func createDeviceFrame(using screenshot: UIScreenshot, count: Int) async throws -> (image: ShareableImage, device: DeviceInfo) {
        guard let resolved = await resolveDevice(for: screenshot) else {
            throw SBError.unsupportedImage
        }
        
        let styled = persistenceManager.applyingPreferredStyle(to: resolved)
        let device = imageResults.overrides.indices.contains(count) ? imageResults.overrides[count].applied(to: styled) : styled
        
        return (try makeShareableImage(from: screenshot, device: device, count: count), device)
    }
    
    /// Frames a screenshot with a device and writes the result to a temporary file.
    private func makeShareableImage(from screenshot: UIScreenshot, device: DeviceInfo, count: Int) throws -> ShareableImage {
        let framedScreenshot = try screenshot.framedScreenshot(quality: persistenceManager.imageQuality, device: device)
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
    
    /// Rebuilds `styleOptions` from the devices in the current screenshots.
    ///
    /// The selections shown are the choices for all screenshots. A screenshot with a choice of its own can differ.
    private func refreshStyleOptions() {
        var names = [String]()
        var groups = [String: [DeviceInfo]]()
        
        for device in imageResults.devices where device.hasColorOptions || device.hasViewOptions {
            if groups[device.name] == nil { names.append(device.name) }
            groups[device.name, default: []].append(device)
        }
        
        styleOptions = names.compactMap { name -> DeviceStyleOption? in
            guard let group = groups[name] else { return nil }
            let colored = group.first(where: \.hasColorOptions)
            
            // A device with several screens, like the iPhone Duo, is one option with a set of views per screen.
            var seenScreens = Set<String>()
            let screens = group.compactMap { device -> DeviceStyleOption.Screen? in
                guard device.hasViewOptions, seenScreens.insert(device.viewPreferenceKey).inserted else { return nil }
                
                return DeviceStyleOption.Screen(
                    screenName: device.screenName,
                    viewKey: device.viewPreferenceKey,
                    views: device.views,
                    selectedView: currentView(for: device)
                )
            }
            
            return DeviceStyleOption(
                deviceName: name,
                colors: colored?.colors ?? [],
                selectedColor: colored.flatMap(currentColor(for:)),
                screens: screens
            )
        }
    }
    
    /// The color chosen for all of a device's screenshots: the saved one if the device has it, otherwise its default.
    private func currentColor(for device: DeviceInfo) -> String? {
        persistenceManager.preferredColor(for: device.name).flatMap { device.colors.contains($0) ? $0 : nil } ?? device.colors.first
    }
    
    /// The view chosen for all of a screen's screenshots: the saved one if the screen has it, otherwise its default.
    private func currentView(for device: DeviceInfo) -> String {
        persistenceManager.preferredView(forKey: device.viewPreferenceKey).flatMap { device.views.contains($0) ? $0 : nil }
            ?? device.views.first ?? ""
    }
    
    private func clearTemporaryDirectory() {
        guard let contents = try? fileManager.contentsOfDirectory(at: .temporaryDirectory) else { return }
        for url in contents {
            try? fileManager.removeItem(at: url)
        }
    }
    
    // MARK: - Public
    
    /// Checks if the user has permission to save screenshot, and if so starts
    /// the file importing process. If not, it shows the purchase sheet.
    public func attemptToImportFile() async {
        guard await eligibilityUseCase.canProceedWithPhotoSelection() else {
            showPurchaseView = true
            return
        }
        
        isImportingFile = true
    }
    
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
    
    public func didOpenViaControlCenter(id: Int) async {
        do {
            try await processSelectedPhotos(source: .controlCenter(id))
        } catch {
            self.error = error
        }
    }
    
    /// Triggered by a widget deep link to kick off the image pipeline using `photoAssetID` as the image source
    public func didOpenViaDeepLink(_ url: URL) async {
        do {
            try await processSelectedPhotos(source: .photoAssetID(url))
        } catch {
            self.error = error
        }
    }
    
    /// Shows the user the photo picker and then uses their selection to kick off the image pipeline
    /// using `photoPicker` as the image source
    public func imageSelectionsDidChange() async {
        do {
            if let video = imageSelections.first(where: \.isVideo) {
                try await processVideo { try await video.loadVideoURL() }
                return
            }
            
            try await processSelectedPhotos(source: .photoPicker(imageSelections))
        } catch {
            self.error = error
        }
    }
    
    /// If not loading, show the photo picker.
    public func selectPhotos() async {
        guard await eligibilityUseCase.canProceedWithPhotoSelection() else {
            showPurchaseView = true
            return
        }
        
        guard !isLoading else {
            logger.fault("Trying to select photos while in a loading state.")
            return
        }
        
        showPhotosPicker = true
    }
    
    /// Clears all images when the user backgrounds the app, if the setting is enabled.
    public func clearImagesOnAppBackground() {
        guard persistenceManager.clearImagesOnAppBackground else { return }
        logger.info("Clearing images on app background")
        
        clearContent()
    }
    
    /// Clears all images and reverts the viewState back to individual placeholder
    ///
    /// - Warning: `imageResults.removeAll()` causes a small memory leak.
    public func clearContent() {
        guard error as? SBError != SBError.lowMemoryWarning else {
            logger.info("Not clearing all content due to low memory warning.")
            return
        }
        
        logger.info("Clearing all content")
        
        stopCombinedImageTask()
        imageResults.removeAll()
        framedVideo = nil
        styleOptions = []
        imageSelections.removeAll()
        viewState = .individualPlaceholder
        imageType = .individual
        clearTemporaryDirectory()
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
    
    /// Copies a single framed screenshot to the clipboard
    public func copy(_ image: UIFramedScreenshot) {
        UIPasteboard.general.image = image
        showCopyToast = true
        logger.debug("Copying 1 image.")
    }

    /// Copies multiple framed screenshots to the clipboard using PNG data
    public func copy(_ images: [UIFramedScreenshot]) {
        guard !images.isEmpty else { return }

        if images.count == 1, let first = images.first {
            UIPasteboard.general.image = first
        } else {
            UIPasteboard.general.set(images)
        }

        showCopyToast = true
        logger.debug("Copying \(images.count) image(s).")
    }
    
    /// Saves a framed screenshot to the users photo library
    public func saveToPhotos(_ image: UIFramedScreenshot) async {
        do {
            try await photoLibraryManager.save(image)
            showQuickSaveToast = true
            logger.debug("Manually saving image to photo library.")
        } catch {
            logger.error("Error manually saving image to photo library: \(error.localizedDescription, privacy: .public).")
            self.error = error
        }
    }
    
    /// Saves a framed video to the users photo library
    public func saveVideoToPhotos(_ video: FramedVideo) async {
        do {
            try await photoLibraryManager.saveVideo(video.url)
            showQuickSaveToast = true
            logger.debug("Manually saving video to photo library.")
        } catch {
            logger.error("Error manually saving video to photo library: \(error.localizedDescription, privacy: .public).")
            self.error = error
        }
    }
    
    /// Saves a framed screenshot to iCloud using the url
    public func saveToiCloud(_ url: URL) {
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
                    if let videoURL = urls.first(where: { UTType(filenameExtension: $0.pathExtension)?.conforms(to: .movie) == true }) {
                        try await processVideo { try Self.copyToTemporaryDirectory(videoURL) }
                        return
                    }
                    
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
    
    /// Re-runs the image pipeline with the images reversed.
    ///
    /// This will change the order of both the individual and combined images.
    public func reverseImages() async {
        logger.info("Re-running pipeline to reverse combined images.")

        isLoading = true
        defer { isLoading = false }
        
        await combinedImageTask?.value
        imageResults.reverseImages()
        await combineDeviceFrames()
        
        guard let combined = imageResults.combined else {
            logger.fault("Processing selected photos returning early because combined image results has no image.")
            error = SBError.unsupportedImage
            return
        }
        
        logger.fault("Setting viewState to combinedImages")
        viewState = .combinedImages(combined)
        isLoading = false
        
        // Only the combined image changed. The individual images are the same, just in a new order.
        await runAutoActions(savingIndividualImages: [])
    }
    
    /// Saves a frame color as the default for a device, then re-frames the screenshots that use it.
    ///
    /// A screenshot with a color of its own keeps it.
    public func didSelectColor(_ color: String, forDeviceNamed deviceName: String) async {
        guard
            let sample = imageResults.devices.first(where: { $0.name == deviceName && $0.hasColorOptions }),
            sample.colors.contains(color),
            currentColor(for: sample) != color
        else {
            return
        }
        
        persistenceManager.setPreferredColor(color, for: deviceName)
        
        let changed = restyleDevices(
            matching: { $0.name == deviceName },
            ignoring: \.color,
            apply: { $0.withColor(color) }
        )
        
        refreshStyleOptions()
        await reframe(changed)
    }
    
    /// Saves a frame view as the default for a screen, then re-frames the screenshots that use it.
    ///
    /// A view is another look of a screen, such as the iPhone Duo's outer screen open instead of closed or its inner
    /// screen partially open. A screenshot with a view of its own keeps it.
    /// - Parameter viewKey: `DeviceInfo.viewPreferenceKey` of the screen.
    public func didSelectView(_ view: String, forViewKey viewKey: String) async {
        guard
            let sample = imageResults.devices.first(where: { $0.viewPreferenceKey == viewKey && $0.hasViewOptions }),
            sample.views.contains(view),
            currentView(for: sample) != view
        else {
            return
        }
        
        persistenceManager.setPreferredView(view, forKey: viewKey)
        
        let changed = restyleDevices(
            matching: { $0.viewPreferenceKey == viewKey },
            ignoring: \.view,
            apply: { $0.withView(view) }
        )
        
        refreshStyleOptions()
        await reframe(changed)
    }
    
    /// The frame choices for one screenshot, for its context menu. `nil` when there is nothing to choose, which is
    /// also the case when there is only one screenshot, since the toolbar menu covers that.
    public func styleOption(forImageWithID id: ShareableImage.ID) -> DeviceStyleOption? {
        guard
            imageResults.hasMultipleImages,
            let index = imageResults.individual.firstIndex(where: { $0.id == id }),
            index < imageResults.devices.count,
            imageResults.devices[index].hasColorOptions || imageResults.devices[index].hasViewOptions
        else {
            return nil
        }
        
        let device = imageResults.devices[index]
        let screens = device.hasViewOptions
            ? [DeviceStyleOption.Screen(
                screenName: device.screenName,
                viewKey: device.viewPreferenceKey,
                views: device.views,
                selectedView: device.viewName ?? ""
            )]
            : []
        
        var option = DeviceStyleOption(
            deviceName: device.name,
            colors: device.colors,
            selectedColor: device.colorName,
            screens: screens
        )
        option.isCustomized = index < imageResults.overrides.count && !imageResults.overrides[index].isEmpty
        return option
    }
    
    /// Picks a frame color for one screenshot only, then re-frames it and the combined image.
    public func didSelectColor(_ color: String, forImageWithID id: ShareableImage.ID) async {
        guard
            let index = imageResults.individual.firstIndex(where: { $0.id == id }),
            index < imageResults.devices.count,
            imageResults.devices[index].colors.contains(color),
            imageResults.devices[index].colorName != color
        else {
            return
        }
        
        imageResults.overrides[index].color = color
        imageResults.devices[index] = imageResults.devices[index].withColor(color)
        await reframe([index])
    }
    
    /// Picks a frame view for one screenshot only, then re-frames it and the combined image.
    public func didSelectView(_ view: String, forImageWithID id: ShareableImage.ID) async {
        guard
            let index = imageResults.individual.firstIndex(where: { $0.id == id }),
            index < imageResults.devices.count,
            imageResults.devices[index].views.contains(view),
            imageResults.devices[index].viewName != view
        else {
            return
        }
        
        imageResults.overrides[index].view = view
        imageResults.devices[index] = imageResults.devices[index].withView(view)
        await reframe([index])
    }
    
    /// Clears what was picked for one screenshot, so it follows the choice for all of them again.
    public func resetStyle(forImageWithID id: ShareableImage.ID) async {
        guard
            let index = imageResults.individual.firstIndex(where: { $0.id == id }),
            index < imageResults.overrides.count,
            !imageResults.overrides[index].isEmpty
        else {
            return
        }
        
        imageResults.overrides[index] = StyleOverride()
        
        // Back to the device's defaults, then the choices for all screenshots on top.
        var device = imageResults.devices[index]
        device = device.colors.first.map { device.withColor($0) } ?? device
        device = device.views.first.map { device.withView($0) } ?? device
        imageResults.devices[index] = persistenceManager.applyingPreferredStyle(to: device)
        
        await reframe([index])
    }
    
    /// Changes the devices of the screenshots that match, except those with a choice of their own for that setting.
    /// - Returns: The indices of the screenshots whose device changed.
    private func restyleDevices(
        matching isAffected: (DeviceInfo) -> Bool,
        ignoring ownChoice: KeyPath<StyleOverride, String?>,
        apply change: (DeviceInfo) -> DeviceInfo
    ) -> [Int] {
        var changed = [Int]()
        
        for index in imageResults.devices.indices {
            let device = imageResults.devices[index]
            let hasOwnChoice = index < imageResults.overrides.count && imageResults.overrides[index][keyPath: ownChoice] != nil
            
            guard isAffected(device), !hasOwnChoice else { continue }
            
            let updated = change(device)
            guard updated.deviceFrame != device.deviceFrame || updated.viewName != device.viewName else { continue }
            
            imageResults.devices[index] = updated
            changed.append(index)
        }
        
        return changed
    }
    
    /// Re-frames the screenshots at `indices` after their frame style changed, then rebuilds the combined image.
    ///
    /// It reuses the devices already chosen for each screenshot, so it never asks which device to use again, and it
    /// does not count as a new framed screenshot or delete the original screenshots. Then the auto save and auto copy
    /// settings run on the images that changed.
    ///
    /// The current images stay on screen under the loading spinner and are replaced once, like when the image quality
    /// changes or the combined images are reversed.
    private func reframe(_ indices: [Int]) async {
        guard !indices.isEmpty else { return }
        
        logger.info("Re-framing \(indices.count, privacy: .public) screenshot(s) with a new frame style.")
        
        isLoading = true
        defer { isLoading = false }
        
        stopCombinedImageTask()
        
        let previousURLs = indices.map { imageResults.individual[$0].url } + [imageResults.combined?.url].compactMap { $0 }
        
        do {
            var images = imageResults.individual
            var replaced = [ShareableImage]()
            
            for index in indices {
                let image = try makeShareableImage(
                    from: imageResults.originalScreenshots[index],
                    device: imageResults.devices[index],
                    count: index
                )
                
                images[index] = image
                replaced.append(image)
            }
            
            // `viewState` still holds the previous images, so they stay visible until the new ones replace them.
            imageResults.individual = images
            imageResults.combined = nil
            refreshStyleOptions()
            
            switch imageType {
            case .individual:
                viewState = .individualImages(images)
                isLoading = false
                await combineDeviceFrames()
            case .combined:
                await combineDeviceFrames()
                
                guard let combined = imageResults.combined else {
                    logger.fault("Re-framing returned early because combined image results has no image.")
                    throw SBError.unsupportedImage
                }
                
                viewState = .combinedImages(combined)
                isLoading = false
            }
            
            previousURLs.forEach { try? fileManager.removeItem(at: $0) }
            
            // The images changed, so the auto save and auto copy settings apply to the new ones.
            await runAutoActions(savingIndividualImages: replaced)
        } catch {
            logger.error("Could not re-frame screenshots: \(error.localizedDescription, privacy: .public).")
            self.error = error
        }
    }
}
