//
//  PhotoLibraryManager.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 4/23/23.
//

import SwiftUI
import Photos
import PhotosUI

public final class PhotoLibraryManager: ObservableObject, PhotoLibraryManaging {
    public static let shared = PhotoLibraryManager()
    private let photoLibrary = PHPhotoLibrary.shared()
    public let photoAdditionStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

    // MARK: - Initializer
    
    private init() {}
    
    
    // MARK: - Helpers
    
    public func requestPhotoLibraryAdditionAuthorization() async {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }
    
    public func savePhoto(at url: URL) async throws {
        try await photoLibrary.performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
        }
    }
    
    public func save(_ image: UIImage) async throws {
        try await photoLibrary.performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
    
    public func delete(_ itemIdentifiers: [String]) async throws {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: itemIdentifiers, options: nil)
        try await photoLibrary.performChanges {
            PHAssetChangeRequest.deleteAssets(assets)
        }
    }
}
