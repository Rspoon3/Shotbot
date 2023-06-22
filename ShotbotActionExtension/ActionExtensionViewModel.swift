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

@MainActor final class ActionExtensionViewModel: ObservableObject {
    let canSaveFramedScreenshot: Bool
    private let attachments: [NSItemProvider]
    private let extensionContext: NSExtensionContext
    private let imageTypeIdentifier = UTType.image.identifier
    private let imageTitle = "Framed Screenshot"
    private var count = 1
    @Published var shareableImages: [ShareableImage]?
    private var persistenceManager: any PersistenceManaging

    var title: String {
        let value = count - 1
            
        if value == 1 {
            return "\(value.formatted()) Screenshot"
        } else {
            return "\(value.formatted()) Screenshots"
        }
    }
    
    // MARK: - Initializer
    
    init(
        attachments: [NSItemProvider],
        extensionContext: NSExtensionContext,
        canSaveFramedScreenshot: Bool,
        persistenceManager: any PersistenceManaging = PersistenceManager.shared
    ) {
        self.attachments = attachments
        self.extensionContext = extensionContext
        self.canSaveFramedScreenshot = canSaveFramedScreenshot
        self.persistenceManager = persistenceManager
        
        guard canSaveFramedScreenshot else { return }
        
        loadAttachments()
    }
    
    // MARK: - Public
    
    func loadAttachments() {
        Task(priority: .userInitiated) {
            shareableImages = await attachments.asyncCompactMap { attachment -> ShareableImage? in
                let path = "\(imageTitle) \(count).png"
                let temporaryURL = URL.temporaryDirectory.appending(path: path)
                count += 1

                guard
                    attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier),
                    let result = try? await attachment.loadItem(forTypeIdentifier: UTType.image.identifier)
                else {
                    return nil
                }
                
                let screenshot: UIImage
                
                if let image = result as? UIImage {
                    let size = CGSize(
                        width: image.size.width * image.scale,
                        height: image.size.height * image.scale
                    )
                    
                    screenshot = image.resized(to: size)
                } else if let imageURL = result as? URL {
                    guard
                        let data = try? Data(contentsOf: imageURL),
                        let screenshotFromData = UIImage(data: data)
                    else {
                        return nil
                    }
                    
                    screenshot = screenshotFromData
                } else {
                    return nil
                }
                
                guard
                    let device = DeviceInfo.all().first(where: {$0.inputSize == screenshot.size}),
                    let frameImage = device.framed(using: screenshot)?.scaled(to: PersistenceManager.shared.imageQuality.value),
                    let framedImageData = frameImage.pngData(),
                    let _ = try? framedImageData.write(to: temporaryURL)
                else {
                    return nil
                }

                persistenceManager.deviceFrameCreations += 1
                
                return ShareableImage(
                    framedScreenshot: frameImage,
                    url: temporaryURL
                )
            }
        }
    }
    
    func cancelButtonTapped() {
        extensionContext.completeRequest(returningItems: [], completionHandler: nil)
    }
}
