//
//  CreateFramedScreenshotsIntent.swift
//  Testing
//
//  Created by Richard Witherspoon on 4/19/23.
//

import SwiftUI
import AppIntents
import CollectionConcurrencyKit
import Models
import Persistence
import MediaManager

struct CreateFramedScreenshotsIntent: AppIntent {
    static let intentClassName = "CreateFramedScreenshotsIntent"
    static var title: LocalizedStringResource = "Create Framed Screenshots"
    static var description = IntentDescription("Creates framed screenshots with a device frame using the images passed in.")
    
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
    var imageQuality: ImageQuality

    static var parameterSummary: some ParameterSummary {
        Summary("Create screenshots from \(\.$images)") {
            \.$saveToFiles
            \.$saveToPhotos
            \.$imageQuality
        }
    }
    
    func perform() async throws -> some IntentResult & ReturnsValue<[IntentFile]> {
        let persistenceManager = PersistenceManager.shared
        
        guard persistenceManager.canSaveFramedScreenshot else {
            throw SBError.proSubscriptionRequired
        }
        
        let screenshots = try await images.asyncCompactMap { file -> IntentFile? in
            let url = try await createDeviceFrame(using: file.data)
            
            var file = IntentFile(fileURL: url, type: .image)
            file.removedOnCompletion = true
            
            return file
        }
        
        persistenceManager.deviceFrameCreations += screenshots.count
        
        return .result(value: screenshots)
    }
    
    private func createDeviceFrame(using data: Data) async throws -> URL {
        guard let screenshot = UIImage(data: data) else {
            throw SBError.noImage
        }
        guard let device = DeviceInfo.all().first(where: {$0.inputSize == screenshot.size}) else {
            throw SBError.unsupportedDevice
        }
        guard let image = device.framed(using: screenshot)?.scaled(to: imageQuality.value) else {
            throw SBError.framing
        }
        guard let data = image.pngData() else {
            throw SBError.noData
        }
        
        let path = "\(UUID().uuidString).png"
        let temporaryDirectoryURL = URL.temporaryDirectory.appending(path: path)
        
        try data.write(to: temporaryDirectoryURL)
                       
        if saveToFiles {
            let destination = URL.documentsDirectory.appending(path: path)
            try FileManager.default.copyItem(at: temporaryDirectoryURL, to: destination)
        }
        
        if saveToPhotos {
            try await PhotoLibraryManager.shared.savePhoto(at: temporaryDirectoryURL)
        }
        
        return temporaryDirectoryURL
    }
}
