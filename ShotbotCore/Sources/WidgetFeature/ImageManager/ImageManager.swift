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
    
// The simulator does not have mediaSubtype so just ignore it.
#if targetEnvironment(simulator)
    private let typePredicate = NSPredicate(format: "creationDate > %@", Date.distantPast as NSDate)
#else
    private let typePredicate = NSPredicate(format: "mediaSubtype = %d", PHAssetMediaSubtype.photoScreenshot.rawValue)
#endif
    
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
    
    /// An enumeration representing the options for fetching screenshots from the user's photo library.
    ///
    /// `ScreenshotFetchOption` defines the different ways to fetch screenshots, including fetching by a specific URL, a specific size, or simply retrieving the most recent screenshot.
    ///
    /// This enum is typically used in conjunction with methods that allow you to retrieve screenshots in various ways, based on the user's input or system configuration.
    public enum ScreenshotFetchOption {
        /// Fetches a screenshot based on the asset ID derived from the provided URL.
        case url(URL)
        
        /// Fetches the most recent screenshot scaled to the provided size.
        case size(CGSize)
        
        /// Fetches the most recent screenshot without any additional size adjustments.
        case latest
    }
    
    // MARK: - Initializer
    
    public init(client: PHImageClient = .live) {
        self.client = client
    }
    
    // MARK: - Public
    
    /// Fetches the latest screenshot from the user's photo library based on the provided option.
    ///
    /// This function allows you to retrieve a screenshot from the user's photo library, either by a specified URL (representing an asset), by a specific size for the latest screenshot, or simply the most recent screenshot.
    /// - Parameters:
    ///   - option: An enum value of type `ScreenshotFetchOption` that determines how the screenshot is fetched. You can provide:
    ///     - `.url(URL)`: Fetches the screenshot based on the asset ID derived from the given URL.
    ///     - `.size(CGSize)`: Fetches the most recent screenshot with the given size.
    ///     - `.latest`: Fetches the most recent screenshot.
    /// - Returns: A tuple containing the fetched `UIImage` and the asset's local identifier (`String?`). The asset identifier may be `nil` if no asset is found.
    /// - Throws:
    ///   - `ImageManagerError.noImageData`: If no screenshot is available in the user's photo library.
    ///   - `ImageManagerError.invalidImageSize`: If the target size for the image is invalid.
    /// - Note: If no size is provided in the `.size` option, the asset's original size will be used.
    public func latestScreenshot(using option: ScreenshotFetchOption) async throws -> (image: UIImage, assetID: String?) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.fetchLimit = 1
        
        let result: PHFetchResult<PHAsset>
        var targetSize: CGSize?
        
        switch option {
        case .url(let url):
            let assetID = try deepLinkManager.deepLinkValue(from: url)
            result = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: fetchOptions)
        case .size(let size):
            fetchOptions.sortDescriptors = [creationDateSortDescriptor]
            fetchOptions.predicate = typePredicate
            result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            targetSize = size
        case .latest:
            fetchOptions.sortDescriptors = [creationDateSortDescriptor]
            fetchOptions.predicate = typePredicate
            result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        }
        
        guard let latestScreenshotAsset = result.firstObject else {
            throw ImageManagerError.noImageData
        }
        
        // If no provided size, use asset's original size
        if targetSize == nil {
            targetSize = .init(
                width: latestScreenshotAsset.pixelWidth,
                height: latestScreenshotAsset.pixelHeight
            )
        }
        
        guard let targetSize else {
            throw ImageManagerError.invalidImageSize
        }
        
        // Request the image
        let image = try await client.requestImage(
            latestScreenshotAsset,
            targetSize,
            .aspectFit,
            imageRequestOptions
        )
        
        return (image, latestScreenshotAsset.localIdentifier)
    }
        
    /// Fetches multiple screenshots from the user's photo library based on the specified time interval.
    ///
    /// This function retrieves all screenshots taken within a specified time interval, defined by the provided `DurationWidgetOption`.
    /// The screenshots are fetched asynchronously from the photo library and returned as an array of `UIImage`.
    ///
    /// - Parameter option: A `DurationWidgetOption` that determines the time interval for fetching screenshots. This includes the date component (such as minutes or hours) and the value (how far back to look).
    ///
    /// - Returns: An array of `UIImage` representing the screenshots taken within the specified time interval.
    ///
    /// - Throws:
    ///   - `ImageManagerError.invalidDate`: If the calculated start date is invalid.
    ///   - `WidgetError.noImages(for:)`: If no images are found within the specified time interval.
    public func multipleScreenshots(for option: DurationWidgetOption) async throws -> [UIImage] {
        guard let startDate = Calendar.current.date(
            byAdding: option.dateComponent,
            value: -option.dateValue,
            to: .now
        ) else {
            throw ImageManagerError.invalidDate
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
        
        let images = try await result.phAssets.asyncCompactMap { asset in
            let image = try await client.requestImage(
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
    
    /// A custom error type used by `ImageManager` to represent errors related to image handling and fetching.
    ///
    /// The `ImageManagerError` struct conforms to `LocalizedError` and provides detailed error descriptions and recovery suggestions
    /// for specific image-related problems, such as missing image data, invalid image sizes, or date-related issues.
    ///
    /// - Properties:
    ///   - `errorDescription`: A localized description of the error.
    ///   - `recoverySuggestion`: A suggestion for the user to recover from the error.
    public struct ImageManagerError: LocalizedError {
        public let errorDescription: String?
        public let recoverySuggestion: String?
        
        public static let noImageData = Self(
            errorDescription: "No image data",
            recoverySuggestion: "The data for this image could not be fetched"
        )
        
        public static let invalidImageSize = Self(
            errorDescription: "Invalid Image Size",
            recoverySuggestion: "There was a problems sizing the image"
        )
        
        public static let invalidDate = Self(
            errorDescription: "Invalid Date",
            recoverySuggestion: "There was a problem with the specified date"
        )
    }
}
