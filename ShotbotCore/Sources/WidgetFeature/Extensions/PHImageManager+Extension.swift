//
//  PHImageManager+Extension.swift
//
//
//  Created by Richard Witherspoon on 7/19/24.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

import Photos
import Models

extension PHImageManager {
    public func requestImage(
        for asset: PHAsset,
        targetSize: CGSize,
        contentMode: PHImageContentMode,
        options: PHImageRequestOptions?
    ) async -> (PlatformImage?, [AnyHashable : Any]?) {
        var callCount = 0
        
        return await withCheckedContinuation { continuation in
            requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: contentMode,
                options: options
            ) { image, dict in
                guard callCount == 0 else { return }
                callCount += 1
                continuation.resume(returning: (image, dict))
            }
        }
    }
}
