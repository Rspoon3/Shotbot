//
//  FramedScreenshotView.swift
//  ShotbotCore
//
//  Created by Claude on 6/28/25.
//

import SwiftUI
import Models

public struct FramedScreenshotView: View {
    @Environment(\.displayScale) private var displayScale
    public let processedScreenshot: ProcessedScreenshot
    @State private var opacity: CGFloat = 1
    
    public init(processedScreenshot: ProcessedScreenshot) {
        self.processedScreenshot = processedScreenshot
    }
    
    private var screenshot: UIImage {
        processedScreenshot.image
    }
    
    private var deviceInfo: DeviceInfo {
        processedScreenshot.deviceInfo
    }
    
    private var frameImage: UIImage? {
        deviceInfo.frameImage()
    }
    
    private var frameSize: CGSize {
        frameImage?.size ?? .zero
    }
    
    private var scaleEffect: CGFloat {
        if screenshot.size.width > screenshot.size.height {
            screenshot.size.width / frameSize.width
        } else {
            screenshot.size.height / frameSize.height
        }
    }
    
    public var body: some View {
        if let frameImage {
            Image(uiImage: frameImage)
                .resizable()
                .aspectRatio(frameSize, contentMode: .fit)
                .opacity(opacity)
                .background {
                    Image(uiImage: screenshot)
                        .resizable()
                        .aspectRatio(screenshot.size, contentMode: .fit)
                        .scaleEffect(scaleEffect)
                }
                .onTapGesture {
                    if opacity == 1 {
                        opacity = 0.5
                    } else {
                        opacity = 1
                    }
                }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct FramedScreenshotView_Previews: PreviewProvider {
    static var previews: some View {
        if let testImage = UIImage(systemName: "photo")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 400)
        ),
        let deviceInfo = DeviceInfo.all().first {
            let processedScreenshot = ProcessedScreenshot(
                image: testImage,
                deviceInfo: deviceInfo
            )
            FramedScreenshotView(processedScreenshot: processedScreenshot)
                .padding()
        }
    }
}
#endif
