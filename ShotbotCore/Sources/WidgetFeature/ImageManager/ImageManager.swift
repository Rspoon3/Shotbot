//
//  ImageManager.swift
//  ShotbotCore
//
//  Created by Richard Witherspoon on 7/22/24.
//

import UIKit
import Photos
import CollectionConcurrencyKit

public struct ImageManager: ImageManaging {
    private let client: PHImageClient
    private let deepLinkManager = DeepLinkManager()
    private let typePredicate = NSPredicate(format: "mediaSubtype = %d", PHAssetMediaSubtype.photoScreenshot.rawValue)
    private let creationDateSortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
    
    private var imageRequestOptions: PHImageRequestOptions {
        let requestOptions = PHImageRequestOptions()
        requestOptions.version = .original
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isNetworkAccessAllowed = true
        if #available(iOS 17, *) {
            requestOptions.allowSecondaryDegradedImage = false
        }
        return requestOptions
    }
    
    // MARK: - Initializer
    
    public init(client: PHImageClient = .live) {
        self.client = client
    }
    
    // MARK: - Public
    
    /// Gets the latest screenshot based on the assetID in the passed in URL.
    public func latestScreenshot(from url: URL) async throws -> UIImage {
        let assetID = try deepLinkManager.deepLinkValue(from: url)

        let fetchOptions = PHFetchOptions()
        fetchOptions.fetchLimit = 1
        
        let result = PHAsset.fetchAssets(
            withLocalIdentifiers: [assetID],
            options: fetchOptions
        )
        
        guard let latestScreenshotAsset = result.firstObject else {
            throw ImageManagerError.noImageData
        }
                
        let image = await client.requestImage(
            latestScreenshotAsset,
            .init(
                width: latestScreenshotAsset.pixelWidth,
                height: latestScreenshotAsset.pixelHeight
            ),
            .aspectFit,
            imageRequestOptions
        )
        
        guard let image else {
            throw ImageManagerError.noImageData
        }
        
        return image
    }
    
    /// Gets the latest screenshot with the target sized passed in.
    /// Returns the image and the image assetID.
    public func latestScreenshot(targetSize: CGSize) async throws -> (image: UIImage, assetID: String)  {
        let fetchOptions = PHFetchOptions()
        fetchOptions.fetchLimit = 1
        fetchOptions.sortDescriptors = [creationDateSortDescriptor]
        fetchOptions.predicate = typePredicate
        
        let result = PHAsset.fetchAssets(
            with: .image,
            options: fetchOptions
        )
        
        guard let latestScreenshotAsset = result.firstObject else {
            throw ImageManagerError.noImageData
        }
                
        let image = await client.requestImage(
            latestScreenshotAsset,
            targetSize,
            .aspectFit,
            imageRequestOptions
        )
        
        guard let image else {
            throw ImageManagerError.noImageData
        }
        
        return (image, latestScreenshotAsset.localIdentifier)
    }
    
    /// Gets the screenshots over the specified duration included in the passed in URL.
    public func multipleScreenshots(from url: URL) async throws -> [UIImage] {
        let durationString = try deepLinkManager.deepLinkValue(from: url)

        guard
            let duration = Int(durationString),
            let option = DurationWidgetOption(rawValue: duration),
            let startDate = Calendar.current.date(
                byAdding: option.dateComponent,
                value: -option.dateValue,
                to: .now
            )
        else {
            throw DeepLinkManager.DeepLinkManagerError.badDeepLinkURL
        }
        
        let fetchOptions = PHFetchOptions()
        let timePredicate = NSPredicate(format: "creationDate > %@", startDate as NSDate)
        let compoundPredicate = NSCompoundPredicate(
            type: .and,
            subpredicates: [
                typePredicate,
                timePredicate
            ]
        )
        fetchOptions.predicate = compoundPredicate
        fetchOptions.sortDescriptors = [creationDateSortDescriptor]
        
        let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        let images = await result.phAssets.asyncCompactMap { asset in
            let image = await client.requestImage(
                asset,
                .init(
                    width: asset.pixelWidth,
                    height: asset.pixelHeight
                ),
                .aspectFit,
                imageRequestOptions
            )
            return image
        }
        
        guard !images.isEmpty else {
            throw WidgetError.noImages(for: option)
        }
        
        return images
    }
    
    // MARK: - Errors
    
    public struct ImageManagerError: LocalizedError {
        public let errorDescription: String?
        public let recoverySuggestion: String?
        
        public static let noImageData = Self(
            errorDescription: "No image data",
            recoverySuggestion: "The data for this image could not be fetched"
        )
    }
}
