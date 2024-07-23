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
        switch entry.viewState {
        case .screenshot(let image, let assetID):
            VStack {
                GeometryReader { geo in
                    Image(uiImage: image)
                        .resizable()
                        .frame(size: frame(for: image, using: geo.size))
                        .containerRelativeOrRadius(cornerRadius: showsWidgetContainerBackground ? nil : 4)
                        .frame(maxWidth: .infinity)
                }
                
                HStack {
                    Button(
                        "Refresh",
                        systemImage: "arrow.clockwise",
                        intent: RefreshLatestScreenshotIntent()
                    )
                    Spacer()
                    Button(
                        "Delete",
                        systemImage: "trash",
                        role: .destructive,
                        intent: DeleteLatestScreenshotIntent(assetID: assetID)
                    )
                }
                .labelStyle(.adaptive)
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
    
    func frame(size: CGSize, alignment: Alignment = .center) -> some View {
        self.frame(width: size.width, height: size.height, alignment: alignment)
    }
}
