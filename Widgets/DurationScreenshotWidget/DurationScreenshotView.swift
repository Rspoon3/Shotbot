//
//  DurationScreenshotView.swift
//  WidgetsExtension
//
//  Created by Richard Witherspoon on 7/19/24.
//

import SwiftUI
import WidgetFeature
import WidgetKit

struct DurationScreenshotView : View {
    let entry: DurationScreenshotEntry
    @Environment(\.showsWidgetContainerBackground) private var showsWidgetContainerBackground
    @Environment(\.widgetFamily) private var widgetFamily
    
    var body: some View {
        VStack {
            Text("Combine Screenshots")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                ForEach(DurationWidgetOption.allCases) { option in
                    Link(destination: entry.url(for: option)) {
                        Circle()
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.shortcutsBackground1,
                                        Color.shortcutsBackground2
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay {
                                Text(option.title)
                                    .foregroundStyle(.white)
                                    .font(.headline)
                            }
                    }
                }
            }
            .font(.footnote)
            .frame(maxHeight: .infinity)
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}
