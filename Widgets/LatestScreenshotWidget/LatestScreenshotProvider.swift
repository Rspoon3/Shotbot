//
//  LatestScreenshotProvider.swift
//  Widgets
//
//  Created by Richard Witherspoon on 7/19/24.
//

import WidgetKit
import SwiftUI
import Photos
import MediaManager
import WidgetFeature

struct LatestScreenshotProvider: TimelineProvider {
    let imageManager: any ImageManaging
    
    // MARK: - Initializer
    
    init(imageManager: any ImageManaging = ImageManager()) {
        self.imageManager = imageManager
    }
    
    // MARK: - TimelineProvider
    
    /// Placeholder
    func placeholder(in context: Context) -> LatestScreenshotEntry {
        LatestScreenshotEntry(viewState: .screenshot(.demoScreenshot, ""))
    }
    
    /// Widget Gallery
    func getSnapshot(in context: Context, completion: @escaping (LatestScreenshotEntry) -> Void) {
        Task {
            guard let entry = await timeline(in: context).entries.first else {
                completion(LatestScreenshotEntry(viewState: .screenshot(.demoScreenshot, "")))
                return
            }
            
            completion(entry)
        }
    }
    
    /// Added Widget
    func getTimeline(in context: Context, completion: @escaping (Timeline<LatestScreenshotEntry>) -> Void) {
        Task {
            let timeline = await timeline(in: context)
            completion(timeline)
        }
    }
    
    // MARK: - Private Helpers
    
    private func timeline(in context: Context) async -> Timeline<LatestScreenshotEntry> {
        do {
            let (image, assetID) = try await imageManager.latestScreenshot(targetSize: context.displaySize * 3)
            let currentDate = Date()
            let entries = (0..<6).compactMap { hourOffset -> LatestScreenshotEntry? in
                guard let entryDate = Calendar.current.date(
                    byAdding: .hour,
                    value: hourOffset,
                    to: currentDate
                ) else { return nil }
                
                return LatestScreenshotEntry(
                    date: entryDate,
                    viewState: .screenshot(image, assetID)
                )
            }
            
            return Timeline(
                entries: entries,
                policy: .atEnd
            )
        } catch {
            return errorTimeline()
        }
    }
    
    private func errorTimeline() -> Timeline<LatestScreenshotEntry> {
        let entryDate = Calendar.current.date(
            byAdding: .hour,
            value: 1,
            to: .now
        ) ?? .distantFuture
        
        let entry = LatestScreenshotEntry(
            date: entryDate,
            viewState: .error
        )
        
        return Timeline(
            entries: [entry],
            policy: .atEnd
        )
    }
}