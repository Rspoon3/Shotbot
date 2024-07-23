//
//  DurationScreenshotView.swift
//  WidgetsExtension
//
//  Created by Richard Witherspoon on 7/19/24.
//

import SwiftUI

struct DurationScreenshotView : View {
    var entry: DurationScreenshotEntry
    @Environment(\.showsWidgetContainerBackground) private var showsWidgetContainerBackground
    @Environment(\.widgetFamily) private var widgetFamily
    
    private func frame(for image: UIImage, using geoSize: CGSize) -> CGSize {
        if image.size.height > image.size.width { // Tall
            return .init(
                width: geoSize.height / image.size.aspectRatio,
                height: geoSize.height
            )
        } else { // Wide
            return .init(
                width: geoSize.width,
                height: geoSize.width * image.size.aspectRatio
            )
        }
    }
    
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
