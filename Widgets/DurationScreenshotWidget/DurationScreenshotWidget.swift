//
//  DurationScreenshotWidget.swift
//  WidgetsExtension
//
//  Created by Richard Witherspoon on 7/19/24.
//

import SwiftUI
import WidgetKit

struct DurationScreenshotWidget: Widget {
    let kind: String = "Duration Screenshots"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: DurationScreenshotProvider()
        ) { entry in
            DurationScreenshotView(entry: entry)
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("Duration Screenshot")
        .description("Combine screenshots over the specified duration.")
        .disfavoredLocations(
            [.lockScreen],
            for: [
                .systemSmall,
                .systemLarge,
                .systemExtraLarge,
                .accessoryInline,
                .accessoryCircular,
                .accessoryRectangular
            ]
        )
    }
}

#Preview(as: .systemMedium) {
    DurationScreenshotWidget()
} timeline: {
    DurationScreenshotEntry()
}
