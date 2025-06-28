//
//  FramedScreenshotsComposition.swift
//  ShotbotCore
//
//  Created by Claude on 6/28/25.
//

import SwiftUI

public struct FramedScreenshotsComposition: View {
    public let screenshots: [UIImage]
    public let spacing: CGFloat
    public let padding: CGFloat
    
    public init(
        screenshots: [UIImage],
        spacing: CGFloat = 16,
        padding: CGFloat = 32
    ) {
        self.screenshots = screenshots
        self.spacing = spacing
        self.padding = padding
    }
    
    public var body: some View {
        HStack(spacing: spacing) {
            ForEach(screenshots, id: \.self) { screenshot in
                FramedScreenshotView(screenshot: screenshot)
            }
        }
        //        .padding(padding)
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
        if let testImage = UIImage(systemName: "photo")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 400)
        ) {
            FramedScreenshotsComposition(
                screenshots: [testImage, testImage]
            )
        }
    }
}
#endif
