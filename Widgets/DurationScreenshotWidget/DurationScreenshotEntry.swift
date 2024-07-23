//
//  DurationScreenshotEntry.swift
//  WidgetsExtension
//
//  Created by Richard Witherspoon on 7/19/24.
//

import UIKit
import WidgetKit
import Photos

struct DurationScreenshotEntry: TimelineEntry {
    let date: Date = .now
    
    func url(for option: DurationWidgetOption) -> URL {
        var components = URLComponents(string: "shotbot://durationScreenshots")
        components?.queryItems = [
            URLQueryItem(
                name: "optionValue",
                value: option.rawValue.description
            )
        ]
        return components!.url!
    }
}
