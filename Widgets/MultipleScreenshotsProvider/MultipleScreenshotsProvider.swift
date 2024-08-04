//
//  MultipleScreenshotsProvider.swift
//  Widgets
//
//  Created by Richard Witherspoon on 7/19/24.
//

import WidgetKit
import SwiftUI
import Photos
import MediaManager

struct MultipleScreenshotsProvider: TimelineProvider {
    
    /// Placeholder
    func placeholder(in context: Context) -> MultipleScreenshotsEntry {
        MultipleScreenshotsEntry()
    }
    
    /// Widget Gallery
    func getSnapshot(in context: Context, completion: @escaping (MultipleScreenshotsEntry) -> Void) {
        let entry = MultipleScreenshotsEntry()
        completion(entry)
    }
    
    /// Added Widget
    func getTimeline(in context: Context, completion: @escaping (Timeline<MultipleScreenshotsEntry>) -> Void) {
        let entry = MultipleScreenshotsEntry()
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}
