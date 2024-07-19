//
//  Widgets.swift
//  Widgets
//
//  Created by Richard Witherspoon on 7/19/24.
//

import WidgetKit
import SwiftUI
import Photos

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: .now,
            configuration: ConfigurationAppIntent(),
            viewState: .error
        )
    }
    
    /// Widget Gallery
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(
            date: .now,
            configuration: configuration,
            viewState: .screenshot(UIImage(named: "demoScreenshot")!, "")
        )
    }
    
    /// Added a widget to device
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let fetchOptions = PHFetchOptions()
        fetchOptions.fetchLimit = 1
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
//        fetchOptions.predicate = NSPredicate(format: "mediaSubtype = %d", PHAssetMediaSubtype.photoScreenshot.rawValue)
        
        let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        guard let latestScreenshotAsset = result.firstObject else {
            let entryDate = Calendar.current.date(
                byAdding: .hour,
                value: 1,
                to: .now
            ) ?? .distantFuture
            
            let entry = SimpleEntry(
                date: entryDate,
                configuration: configuration,
                viewState: .error
            )
            return Timeline(
                entries: [entry],
                policy: .atEnd
            )
        }
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.version = .original
        requestOptions.deliveryMode = .highQualityFormat
        
        let image = await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: latestScreenshotAsset,
                targetSize: context.displaySize,
                contentMode: .aspectFit,
                options: requestOptions
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
        
        guard let image else {
            let entryDate = Calendar.current.date(
                byAdding: .hour,
                value: 1,
                to: .now
            ) ?? .distantFuture
            
            let entry = SimpleEntry(
                date: entryDate,
                configuration: configuration,
                viewState: .error
            )
            return Timeline(
                entries: [entry],
                policy: .atEnd
            )
        }
        
        let currentDate = Date()
        let entries = (0..<6).compactMap { hourOffset -> SimpleEntry? in
            guard let entryDate = Calendar.current.date(
                byAdding: .hour,
                value: hourOffset,
                to: currentDate
            ) else { return nil }
            
            return SimpleEntry(
                date: entryDate,
                configuration: configuration,
                viewState: .screenshot(image, latestScreenshotAsset.localIdentifier)
            )
        }
        
        return Timeline(
            entries: entries,
            policy: .atEnd
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let viewState: ViewState
    
    var url: URL? {
        guard case let .screenshot(_, assetID) = viewState else { return nil }
        var components = URLComponents(string: "shotbot://latestScreenshot")
        components?.queryItems = [URLQueryItem(name: "assetID", value: assetID)]
        return components?.url
    }
    
    var errorMessage: String {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized:
            return "No photo permissions."
        case .denied, .restricted, .notDetermined:
            return "Invalid photo permissions."
        case .limited:
            return "No screenshot with limited photo permissions."
        @unknown default:
            return "Unknown photo permissions."
        }
    }
    
    enum ViewState {
        case screenshot(UIImage, String)
        case error
    }
}

struct WidgetsEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        switch entry.viewState {
        case .screenshot(let image, let assetID):
            VStack {
                GeometryReader { geo in
                    Image(uiImage: image)
                        .resizable()
                        .frame(
                            width: geo.size.min / image.size.aspectRatio,
                            height: geo.size.min
                        )
                        .clipShape(.containerRelative)
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
        }
    }
}

struct LatestScreenshot: Widget {
    let kind: String = "Latest Screenshot"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: Provider()
        ) { entry in
            WidgetsEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .systemLarge])
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemSmall) {
    LatestScreenshot()
} timeline: {
    SimpleEntry(
        date: .now,
        configuration: .smiley,
        viewState: .screenshot(UIImage(named: "demoScreenshot")!, "")
    )
    SimpleEntry(
        date: .now,
        configuration: .smiley,
        viewState: .screenshot(UIImage(named: "darkMessages")!, "")
    )
    SimpleEntry(
        date: .now,
        configuration: .smiley,
        viewState: .screenshot(UIImage(named: "snapchat")!, "")
    )
}
