//
//  PHImageClient.swift
//  ShotbotCore
//
//  Created by Richard Witherspoon on 7/22/24.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

import Photos
import Models

public struct PHImageClient {
    public var requestImage: (
        _ asset: PHAsset,
        _ targetSize: CGSize,
        _ contentMode: PHImageContentMode,
        _ options: PHImageRequestOptions?
    ) async -> (PlatformImage?, [AnyHashable : Any]?)
    
    // MARK: - Initializer
    
    public init(
        requestImage: @escaping (
            _ asset: PHAsset,
            _ targetSize: CGSize,
            _ contentMode: PHImageContentMode,
            _ options: PHImageRequestOptions?
        ) async -> (PlatformImage?, [AnyHashable : Any]?)
    ) {
        self.requestImage = requestImage
    }
}

public extension PHImageClient {
    static var live: Self {
        return Self { asset, targetSize, contentMode, options in
            await PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: contentMode,
                options: options
            )
        }
    }
    
    #if DEBUG
    static var mockImage: Self {
        return Self { asset, targetSize, contentMode, options in
            (PlatformImage(systemName: "star"), nil)
        }
    }
    #endif
}
