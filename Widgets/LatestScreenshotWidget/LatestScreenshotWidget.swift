//
//  LatestScreenshotWidget.swift
//  WidgetsExtension
//
//  Created by Richard Witherspoon on 7/19/24.
//

import SwiftUI
import WidgetKit
import WidgetFeature

struct LatestScreenshotWidget: Widget {
    private let kind: String = "Latest Screenshot"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: LatestScreenshotProvider()
        ) { entry in
            LatestScreenshotView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .systemLarge])
        .configurationDisplayName("Latest Screenshot")
        .description("Quickly access your latest screenshot to frame.")
        .disfavoredLocations(
            [.lockScreen],
            for: [
                .systemMedium,
                .systemExtraLarge,
                .accessoryInline,
                .accessoryCircular,
                .accessoryRectangular
            ]
        )
    }
}

#Preview(as: .systemSmall) {
    LatestScreenshotWidget()
} timeline: {
    LatestScreenshotEntry(
        viewState: .screenshot(.demoScreenshot, "")
    )
    LatestScreenshotEntry(
        viewState: .screenshot(.darkMessages, "")
    )
    LatestScreenshotEntry(
        viewState: .screenshot(.snapchat, "")
    )
    LatestScreenshotEntry(
        viewState: .error,
        photoLibraryManager: .empty(status: .authorized)
    )
    LatestScreenshotEntry(
        viewState: .error,
        photoLibraryManager: .empty(status: .denied)
    )
    LatestScreenshotEntry(
        viewState: .error,
        photoLibraryManager: .empty(status: .limited)
    )
}
