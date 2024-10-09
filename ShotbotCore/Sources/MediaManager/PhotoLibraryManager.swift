//
//  PhotoLibraryManager.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 4/23/23.
//

import SwiftUI
import Photos
import PhotosUI
import Models

public struct PhotoLibraryManager: Sendable {
    public let photoAdditionStatus: PHAuthorizationStatus
    public var requestPhotoLibraryAdditionAuthorization: @Sendable () async -> Void
    public var savePhoto: @Sendable(URL) async throws -> Void
    public var save: @Sendable(_ at: UIImage) async throws -> Void
    public var delete: @Sendable ([String]) async throws -> Void
    
    public init(
        photoAdditionStatus: PHAuthorizationStatus,
        requestPhotoLibraryAdditionAuthorization: @escaping @Sendable () async -> Void,
        savePhoto: @escaping @Sendable (URL) async throws -> Void,
        save: @escaping @Sendable (UIImage) async throws -> Void,
        delete: @escaping @Sendable ([String]) async throws -> Void
    ) {
        self.photoAdditionStatus = photoAdditionStatus
        self.requestPhotoLibraryAdditionAuthorization = requestPhotoLibraryAdditionAuthorization
        self.savePhoto = savePhoto
        self.save = save
        self.delete = delete
    }
}

public extension PhotoLibraryManager {
    static var live: Self {
        let photoLibrary = PHPhotoLibrary.shared()
        
        return Self(
            photoAdditionStatus: PHPhotoLibrary.authorizationStatus(for: .readWrite),
            requestPhotoLibraryAdditionAuthorization: {
                await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            },
            savePhoto: { url in
                do {
                    try await photoLibrary.performChanges {
                        PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
                    }
                } catch {
                    throw SBError.insufficientPhotoAuthorization
                }
            },
            save: { image in
                do {
                    try await photoLibrary.performChanges {
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    }
                } catch {
                    throw SBError.insufficientPhotoAuthorization
                }
            },
            delete: { itemIdentifiers in
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: itemIdentifiers, options: nil)
                try await photoLibrary.performChanges {
                    PHAssetChangeRequest.deleteAssets(assets)
                }
            }
        )
    }
    
    #if DEBUG
    static func empty(status: PHAuthorizationStatus) -> Self {
        Self(
            photoAdditionStatus: status,
            requestPhotoLibraryAdditionAuthorization: {},
            savePhoto: {_ in },
            save: {_ in },
            delete: {_ in }
        )
    }
    #endif
}
