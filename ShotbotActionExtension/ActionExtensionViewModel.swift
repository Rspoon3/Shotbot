//
//  ActionExtensionViewModel.swift
//  ShotbotActionExtension
//
//  Created by Richard Witherspoon on 4/30/23.
//

@preconcurrency import Foundation
import MobileCoreServices
import UniformTypeIdentifiers
import CollectionConcurrencyKit
import UIKit
import Models
import Persistence
import OSLog
import SBFoundation
import Purchases
import CreateCombinedImageFeature

@MainActor final class ActionExtensionViewModel: ObservableObject {
    private let logger = Logger(category: ActionExtensionViewModel.self)
    private var attachments: [NSItemProvider]
    private let extensionContext: NSExtensionContext
    private let imageTypeIdentifier = UTType.image.identifier
    private let imageTitle = "Framed Screenshot"
    @Published var isReversingImages = false
    @Published var imageType: ImageType
    @Published var shareableImages: [ShareableImage]?
    @Published var shareableCombinedImage: ShareableImage?
    @Published var showGridView: Bool
    @Published var canSaveFramedScreenshot = false
    @Published public var error: Error?
    private var persistenceManager: any PersistenceManaging
    private let fileManager: any FileManaging

    var title: String {
        switch imageType {
        case .individual:
            let value = shareableImages?.count ?? 0
            
            if value == 1 {
                return "\(value.formatted()) Screenshot"
            } else {
                return "\(value.formatted()) Screenshots"
            }
        case.combined:
            return "Combined Screenshots"
        }
    }
    
    var sharableURLs: [URL]? {
        switch imageType {
        case .individual:
            return shareableImages?.compactMap(\.url)
        case .combined:
            guard let shareableCombinedImage else { return nil }
            return [shareableCombinedImage.url]
        }
    }
    
    var hasMultipleImages: Bool {
        shareableImages?.count ?? 0 > 1
    }
    
    var showReverseImageButton: Bool {
        hasMultipleImages && imageType == .combined
    }
    
    var viewTypeImageName: String? {
        guard hasMultipleImages, imageType == .individual else { return nil }
        return persistenceManager.defaultHomeView == .grid ? "ellipsis.rectangle" : "square.grid.2x2"
    }
    
    // MARK: - Initializer
    
    init(
        attachments: [NSItemProvider],
        extensionContext: NSExtensionContext,
        persistenceManager: any PersistenceManaging = PersistenceManager.shared,
        fileManager: any FileManaging = FileManager.default
    ) {
        self.attachments = attachments
        self.extensionContext = extensionContext
        self.persistenceManager = persistenceManager
        self.fileManager = fileManager
        self.showGridView = persistenceManager.defaultHomeView == .grid
        
        logger.notice("attachments: \(attachments.count.formatted(), privacy: .public)")
        
        if persistenceManager.defaultHomeTab == .combined, attachments.count > 1 {
            imageType = .combined
        } else {
            imageType = .individual
        }
    }
    
    // MARK: - Public
    
    func cancelButtonTapped() {
        clearTemporaryDirectory()
        
        extensionContext.completeRequest(
            returningItems: [],
            completionHandler: nil
        )
    }
    
    func loadAttachments() async {
        let eligibilityUseCase = FramedScreenshotEligibilityUseCase()
        let reason = await eligibilityUseCase.canSaveFramedScreenshot(screenshotCount: attachments.count)

        canSaveFramedScreenshot = reason.canSave
        guard canSaveFramedScreenshot else { return }
        
        await createIndividualImages()
        
        if (shareableImages ?? []).count != attachments.count {
            error = SBError.unsupportedImage
            return
        }
        
        Task {
            await createCombineImageIfNeeded()
            
            if let amount = reason.rewardedScreenShotsCount {
                do {
                    try await eligibilityUseCase.consumeExtraScreenshot(amount: attachments.count)
                    logger.info("Consumed \(amount, privacy: .public) extra screenshot(s).")
                } catch {
                    logger.error("Failed to consume \(amount, privacy: .public) extra screenshot(s): \(error.localizedDescription, privacy: .public).")
                }
            }
        }
    }
    
    func reverseImages() async {
        isReversingImages = true
        defer { isReversingImages = false }
        
        attachments.reverse()
        await loadAttachments()
    }
    
    // MARK: - Private
    
    private func createIndividualImages() async {
        var count = 1
        var loopedImages: [ShareableImage] = []
        
        for attachment in attachments {
            let path = "\(imageTitle) \(count).png"
            let temporaryURL = URL.temporaryDirectory.appending(path: path)
            count += 1
                        
            guard
                attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier),
                let result = try? await attachment.loadItem(forTypeIdentifier: UTType.image.identifier),
                let screenshot = getImage(from: result),
                let framedScreenshot = try? screenshot.framedScreenshot(quality: persistenceManager.imageQuality),
                let framedImageData = framedScreenshot.pngData(),
                let _ = try? framedImageData.write(to: temporaryURL)
            else {
                return
            }
            
            persistenceManager.deviceFrameCreations += 1
            
            let sharableImage = ShareableImage(
                framedScreenshot: framedScreenshot,
                url: temporaryURL
            )
            
            loopedImages.append(sharableImage)
        }
        
        shareableImages = loopedImages
    }
    
    private func getImage(from result: any NSSecureCoding) -> UIImage? {
        let image: UIImage?
        
        if let uiImage = result as? UIImage {
            image = uiImage
        } else if let imageURL = result as? URL, let data = try? Data(contentsOf: imageURL) {
            image = UIImage(data: data)
        } else if let data = result as? Data {
            image = UIImage(data: data)
        } else {
            return nil
        }
        
        guard let image else { return nil }
        
        let size = CGSize(
            width: image.size.width * image.scale,
            height: image.size.height * image.scale
        )
        
        return image.resized(to: size)
    }
    
    private func createCombineImageIfNeeded() async {
        guard let shareableImages, shareableImages.count > 1 else { return }
        
        shareableCombinedImage = try? await ImageCombiner().createCombinedImage(
            from: shareableImages.map(\.framedScreenshot),
            imageQuality: persistenceManager.imageQuality.value
        )
        
        guard shareableCombinedImage != nil else { return }
        
        persistenceManager.deviceFrameCreations += 1
    }
    
    private func clearTemporaryDirectory() {
        guard let contents = try? fileManager.contentsOfDirectory(at: .temporaryDirectory) else { return }
        for url in contents {
            try? fileManager.removeItem(at: url)
        }
    }
    
    public func toggleIndividualViewType() {
        switch persistenceManager.defaultHomeView {
        case .grid:
            persistenceManager.defaultHomeView = .tabbed
        case .tabbed:
            persistenceManager.defaultHomeView = .grid
        }
        
        showGridView = persistenceManager.defaultHomeView == .grid && hasMultipleImages
    }
}
