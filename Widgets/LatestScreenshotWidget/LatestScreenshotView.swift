//
//  LatestScreenshotView.swift
//  WidgetsExtension
//
//  Created by Richard Witherspoon on 7/19/24.
//

import SwiftUI

struct LatestScreenshotView : View {
    var entry: LatestScreenshotProvider.Entry
    @Environment(\.showsWidgetContainerBackground) private var showsWidgetContainerBackground
    
    var body: some View {
        switch entry.viewState {
        case .screenshot(let image, _):
            VStack {
                GeometryReader { geo in
                    Image(uiImage: image)
                        .resizable()
                        .frame(
                            width: geo.size.min / image.size.aspectRatio,
                            height: geo.size.min
                        )
                        .containerRelativeOrRadius(cornerRadius: showsWidgetContainerBackground ? nil : 4)
                        .frame(maxWidth: .infinity)
                }
                
                Button(
                    "Refresh",
                    systemImage: "arrow.clockwise",
                    intent: RefreshLatestScreenshotIntent()
                )
                .font(.footnote)
            }
            .widgetURL(entry.url)
            .containerBackground(for: .widget) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.9)
                    .overlay {
                        Rectangle()
                            .background(.ultraThinMaterial)
                    }
            }
        case .error:
            Text(entry.errorMessage)
                .multilineTextAlignment(.center)
                .font(.headline)
                .foregroundStyle(.white)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [
                            Color.shortcutsBackground1,
                            Color.shortcutsBackground2
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
    }
}

private extension View {
    func containerRelativeOrRadius(cornerRadius: Double?) -> AnyView {
        if let cornerRadius {
            AnyView(self.clipShape(RoundedRectangle(cornerRadius: cornerRadius)))
        } else {
            AnyView(self.clipShape(.containerRelative))
        }
    }
}
