//
//  ActionExtensionViewModel.swift
//  ShotbotActionExtension
//
//  Created by Richard Witherspoon on 4/30/23.
//

import MobileCoreServices
import UniformTypeIdentifiers
import CollectionConcurrencyKit
import UIKit
import Models
import Persistence
import OSLog
import SBFoundation
import CreateCombinedImageFeature

@MainActor final class ActionExtensionViewModel: ObservableObject {
    private let logger = Logger(category: ActionExtensionViewModel.self)
    private let attachments: [NSItemProvider]
    private let extensionContext: NSExtensionContext
    private let imageTypeIdentifier = UTType.image.identifier
    private let imageTitle = "Framed Screenshot"
    @Published var imageType: ImageType
    @Published var shareableImages: [ShareableImage]?
    @Published var shareableCombinedImage: ShareableImage?
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
    
    var canSaveFramedScreenshot : Bool {
        persistenceManager.canSaveFramedScreenshot
    }
    
    var hasMultipleImages: Bool {
        shareableImages?.count ?? 0 > 1
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
        
        logger.notice("attachments: \(attachments.count.formatted(), privacy: .public)")
        logger.notice("canSaveFramedScreenshot: \(persistenceManager.canSaveFramedScreenshot, privacy: .public)")
        
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
        guard persistenceManager.canSaveFramedScreenshot else { return }
        await createIndividualImages()
        
        Task {
            await createCombineImageIfNeeded()
        }
    }
    
    // MARK: - Private
    
    private func createIndividualImages() async {
        var count = 1
        
        shareableImages = await attachments.asyncCompactMap { attachment -> ShareableImage? in
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
                return nil
            }
            
            persistenceManager.deviceFrameCreations += 1
            
            return ShareableImage(
                framedScreenshot: framedScreenshot,
                url: temporaryURL
            )
        }
    }
    
    private func getImage(from result: any NSSecureCoding) -> UIImage? {
        if let image = result as? UIImage {
            let size = CGSize(
                width: image.size.width * image.scale,
                height: image.size.height * image.scale
            )
            
            return image.resized(to: size)
        } else if let imageURL = result as? URL {
            guard
                let data = try? Data(contentsOf: imageURL),
                let screenshotFromData = UIImage(data: data)
            else {
                return nil
            }
            
            return screenshotFromData
        } else {
            return nil
        }
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
}
