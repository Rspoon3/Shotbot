//
//  LatestScreenshotView.swift
//  WidgetsExtension
//
//  Created by Richard Witherspoon on 7/19/24.
//

import SwiftUI
import WidgetKit
import Photos

struct LatestScreenshotView : View {
    let entry: LatestScreenshotEntry
    @Environment(\.showsWidgetContainerBackground) private var showsWidgetContainerBackground
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        switch entry.viewState {
        case .screenshot(let image, let assetID):
            VStack {
                GeometryReader { geo in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            size: entry.frameSize(
                                for: image,
                                using: geo.size
                            )
                        )
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


struct LatestScreenshotView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(0...4, id: \.self) { i in
            LatestScreenshotView(
                entry: LatestScreenshotEntry(
                    viewState: .error,
                    photoLibraryManager: .empty(
                        status: PHAuthorizationStatus(rawValue: i)!
                    )
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName(PHAuthorizationStatus(rawValue: i)!.title)
        }
    }
}
