//
//  LatestScreenshotEntry.swift
//  WidgetsExtension
//
//  Created by Richard Witherspoon on 7/19/24.
//

import UIKit
import WidgetKit
import WidgetFeature
import MediaManager
import Photos

struct LatestScreenshotEntry: TimelineEntry {
    let date: Date
    let viewState: ViewState
    let photoLibraryManager: PhotoLibraryManager
    
    var url: URL? {
        guard case let .screenshot(_, assetID) = viewState else { return nil }
        var components = URLComponents(string: "shotbot://\(DeepLink.latestScreenshot.rawValue)")
        components?.queryItems = [URLQueryItem(name: "assetID", value: assetID)]
        return components?.url
    }
    
    var errorMessage: String {
        switch photoLibraryManager.photoAdditionStatus {
        case .authorized:
            return "No screenshots available"
        case .denied, .restricted, .notDetermined:
            return "Invalid photo permission."
        case .limited:
            return "No screenshot with limited photo permissions"
        @unknown default:
            return "Unknown photo permissions"
        }
    }
    
    enum ViewState {
        case screenshot(UIImage, String)
        case error
    }
    
    // MARK: - Initializer
    
    init(
        date: Date = .now,
        viewState: ViewState,
        photoLibraryManager: PhotoLibraryManager = .live
    ) {
        self.date = date
        self.viewState = viewState
        self.photoLibraryManager = photoLibraryManager
    }
    
    // MARK: - Public
    
    func frameSize(for image: UIImage, using geoSize: CGSize) -> CGSize {
        if image.size.height > image.size.width { // Tall
            return .init(
                width: geoSize.height / image.size.aspectRatio,
                height: geoSize.height
            )
        } else { // Wide
            return .init(
                width: geoSize.width,
                height: geoSize.width * image.size.aspectRatio
            )
        }
    }
}
