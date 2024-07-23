//
//  DurationScreenshotProvider.swift
//  Widgets
//
//  Created by Richard Witherspoon on 7/19/24.
//

import WidgetKit
import SwiftUI
import Photos
import MediaManager

struct DurationScreenshotProvider: TimelineProvider {
    
    /// Placeholder
    func placeholder(in context: Context) -> DurationScreenshotEntry {
        DurationScreenshotEntry()
    }
    
    /// Widget Gallery
    func getSnapshot(in context: Context, completion: @escaping (DurationScreenshotEntry) -> Void) {
        let entry = DurationScreenshotEntry()
        completion(entry)
    }
    
    /// Added Widget
    func getTimeline(in context: Context, completion: @escaping (Timeline<DurationScreenshotEntry>) -> Void) {
        let entry = DurationScreenshotEntry()
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}
