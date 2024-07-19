//
//  LatestScreenshotEntry.swift
//  WidgetsExtension
//
//  Created by Richard Witherspoon on 7/19/24.
//

import UIKit
import WidgetKit
import Photos

struct LatestScreenshotEntry: TimelineEntry {
    let date: Date
    let viewState: ViewState
    
    var url: URL? {
        guard case let .screenshot(_, assetID) = viewState else { return nil }
        var components = URLComponents(string: "shotbot://latestScreenshot")
        components?.queryItems = [URLQueryItem(name: "assetID", value: assetID)]
        return components?.url
    }
    
    var errorMessage: String {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
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
    
    init(date: Date = .now, viewState: ViewState) {
        self.date = date
        self.viewState = viewState
    }
}
