//
//  MultipleScreenshotsWidget.swift
//  WidgetsExtension
//
//  Created by Richard Witherspoon on 7/19/24.
//

import SwiftUI
import WidgetKit

struct MultipleScreenshotsWidget: Widget {
    let kind: String = "Multiple Screenshots"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: MultipleScreenshotsProvider()
        ) { entry in
            MultipleScreenshotsView(entry: entry)
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("Multiple Screenshots")
        .description("Frame and combine multiple screenshots over the specified duration.")
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
    MultipleScreenshotsWidget()
} timeline: {
    MultipleScreenshotsEntry()
}
