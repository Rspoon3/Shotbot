//
//  PHImageManager+Extension.swift
//
//
//  Created by Richard Witherspoon on 7/19/24.
//

import UIKit
import Photos

extension PHImageManager {
    public func requestImage(
        for asset: PHAsset,
        targetSize: CGSize,
        contentMode: PHImageContentMode,
        options: PHImageRequestOptions?
    ) async -> (UIImage?, [AnyHashable : Any]?) {
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
