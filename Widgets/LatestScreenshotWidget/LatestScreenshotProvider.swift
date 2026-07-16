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
import AsyncTimelineProvider
@preconcurrency import WidgetKit

struct LatestScreenshotProvider: AsyncTimelineProvider {
    let imageManager: any ImageManaging

    // MARK: - Initializer

    init(imageManager: any ImageManaging = ImageManager()) {
        self.imageManager = imageManager
    }

    // MARK: - AsyncTimelineProvider

    /// Placeholder
    func placeholder(in context: Context) -> LatestScreenshotEntry {
        LatestScreenshotEntry(viewState: .screenshot(.demoScreenshot, ""))
    }

    /// Widget Gallery
    func snapshot(in context: Context) async -> LatestScreenshotEntry {
        guard let entry = await timeline(in: context).entries.first else {
            return LatestScreenshotEntry(viewState: .screenshot(.demoScreenshot, ""))
        }

        return entry
    }

    /// Added Widget
    func timeline(in context: Context) async -> Timeline<LatestScreenshotEntry> {
        do {
            let scaledSize = await context.displaySize * UIScreen.main.scale
            let (image, assetID) = try await imageManager.latestScreenshot(using: .size(scaledSize))
            let currentDate = Date()
            let entries = (0..<6).compactMap { hourOffset -> LatestScreenshotEntry? in
                guard
                    let entryDate = Calendar.current.date(
                        byAdding: .hour,
                        value: hourOffset,
                        to: currentDate
                    ),
                    let assetID
                else {
                    return nil
                }
                
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

    // MARK: - Private Helpers

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
