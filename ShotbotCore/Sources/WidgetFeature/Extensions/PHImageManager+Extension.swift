//
//  PHImageManager+Extension.swift
//
//
//  Created by Richard Witherspoon on 7/19/24.
//

import UIKit
import Photos

extension PHImageManager {
    
    public enum ImageRequestError: Error {
        case cancelled
        case imageDataUnavailable
        case underlyingError(Error)
    }
    
    public func requestImage(
        for asset: PHAsset,
        targetSize: CGSize,
        contentMode: PHImageContentMode,
        options: PHImageRequestOptions? = nil
    ) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: contentMode,
                options: options
            ) { image, info in
                guard let info else {
                    continuation.resume(throwing: ImageRequestError.imageDataUnavailable)
                    return
                }
                
                // Check if the request was canceled.
                if let isCancelled = info[PHImageCancelledKey] as? Bool, isCancelled {
                    continuation.resume(throwing: ImageRequestError.cancelled)
                    return
                }
                
                // Check for errors in the info dictionary.
                if let error = info[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: ImageRequestError.underlyingError(error))
                    return
                }
                
                // Check if the image is degraded. If it is, ignore it.
                if let isDegraded = info[PHImageResultIsDegradedKey] as? Bool, isDegraded {
                    return // Ignore degraded image, wait for full-quality image.
                }
                
                // Ensure the full-quality image is available.
                guard let image = image else {
                    continuation.resume(throwing: ImageRequestError.imageDataUnavailable)
                    return
                }
                
                // Resume with the full-quality image.
                continuation.resume(returning: image)
            }
        }
    }
}
