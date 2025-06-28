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
    public let screenshot: UIImage
    @State private var opacity: CGFloat = 1
    
    public init(screenshot: UIImage) {
        self.screenshot = screenshot
    }
    
    private var deviceInfo: DeviceInfo? {
        DeviceInfo.all().first { $0.inputSize == screenshot.size }
    }
    
    private var frameImage: UIImage? {
        deviceInfo?.frameImage()
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
        ) {
            FramedScreenshotView(screenshot: testImage)
                .padding()
        }
    }
}
#endif
