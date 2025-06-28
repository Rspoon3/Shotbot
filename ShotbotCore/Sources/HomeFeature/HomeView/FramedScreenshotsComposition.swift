//
//  FramedScreenshotsComposition.swift
//  ShotbotCore
//
//  Created by Claude on 6/28/25.
//

import SwiftUI

public struct FramedScreenshotsComposition: View {
    public let screenshots: [ProcessedScreenshot]
    public let spacing: CGFloat
    public let padding: CGFloat
    
    public init(
        screenshots: [ProcessedScreenshot],
        spacing: CGFloat = 16,
        padding: CGFloat = 32
    ) {
        self.screenshots = screenshots
        self.spacing = spacing
        self.padding = padding
    }
    
    public var body: some View {
        HStack(spacing: spacing) {
            ForEach(screenshots) { processedScreenshot in
                FramedScreenshotView(processedScreenshot: processedScreenshot)
            }
        }
        .padding(padding)
        .background {
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Preview

#if DEBUG
struct FramedScreenshotsComposition_Previews: PreviewProvider {
    static var previews: some View {
        let processedScreenshot = ProcessedScreenshot(
            image: UIImage(symbol: .star),
            deviceInfo: .mock
        )
        FramedScreenshotsComposition(
            screenshots: [
                processedScreenshot,
                processedScreenshot
            ]
        )
    }
}
#endif
