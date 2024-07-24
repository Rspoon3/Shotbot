//
//  MultipleScreenshotsEntry.swift
//  WidgetsExtension
//
//  Created by Richard Witherspoon on 7/19/24.
//

import UIKit
import WidgetKit
import WidgetFeature
import Photos

struct MultipleScreenshotsEntry: TimelineEntry {
    let date: Date = .now
    
    // MARK: - Public
    
    func url(for option: DurationWidgetOption) -> URL {
        var components = URLComponents(string: "shotbot://\(DeepLink.multipleScreenshots.rawValue)")
        components?.queryItems = [
            URLQueryItem(
                name: "optionValue",
                value: option.rawValue.description
            )
        ]
        return components!.url!
    }
}
