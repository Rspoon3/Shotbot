//
//  PHImageClient.swift
//  ShotbotCore
//
//  Created by Richard Witherspoon on 7/22/24.
//

import UIKit
import Photos

public struct PHImageClient {
    public var requestImage: (
        _ asset: PHAsset,
        _ targetSize: CGSize,
        _ contentMode: PHImageContentMode,
        _ options: PHImageRequestOptions?
    ) async -> (UIImage?, [AnyHashable : Any]?)
    
    // MARK: - Initializer
    
    public init(
        requestImage: @escaping (
            _ asset: PHAsset,
            _ targetSize: CGSize,
            _ contentMode: PHImageContentMode,
            _ options: PHImageRequestOptions?
        ) async -> (UIImage?, [AnyHashable : Any]?)
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
            (UIImage(systemName: "star"), nil)
        }
    }
    #endif
}