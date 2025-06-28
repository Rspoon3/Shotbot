//
//  FramedScreenshotView.swift
//  ShotbotCore
//
//  Created by Claude on 6/28/25.
//

import SwiftUI
import Models

public struct FramedScreenshotView: View {
    public let screenshot: UIImage
    
    public init(screenshot: UIImage) {
        self.screenshot = screenshot
    }
    
    private var deviceInfo: DeviceInfo? {
        DeviceInfo.all().first { $0.inputSize == screenshot.size }
    }
    
    private var frameImage: UIImage? {
        deviceInfo?.frameImage()
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let deviceInfo, let frameImage {
                    // Calculate the scale to fit the frame within the available space
                    let scale = min(
                        geometry.size.width / frameImage.size.width,
                        geometry.size.height / frameImage.size.height
                    )
                    
                    let frameSize = CGSize(
                        width: frameImage.size.width * scale,
                        height: frameImage.size.height * scale
                    )
                    
                    ZStack {
                        // Screenshot layer (positioned using device info)
                        screenshotView(for: deviceInfo, frameSize: frameSize, scale: scale)
                        
                        // Frame overlay
                        Image(uiImage: frameImage)
                            .resizable()
                            .frame(width: frameSize.width, height: frameSize.height)
                            .allowsHitTesting(false)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Fallback: show screenshot without frame
                    Image(uiImage: screenshot)
                        .resizable()
                        .scaledToFit()
                        .overlay(
                            Text("Unsupported device size")
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)
                                .foregroundColor(.secondary),
                            alignment: .topTrailing
                        )
                }
            }
        }
    }
    
    private func processedScreenshot(for deviceInfo: DeviceInfo) -> UIImage {
        var processed = screenshot
        
        // Apply the same processing as the original implementation
        if let clipEdgesAmount = deviceInfo.clipEdgesAmount {
            processed = screenshot.clipEdges(amount: clipEdgesAmount)
        } else if let cornerRadius = deviceInfo.cornerRadius {
            processed = screenshot.withRoundedCorners(radius: cornerRadius)
        }
        
        if let scaledSize = deviceInfo.scaledSize {
            processed = processed.resized(to: scaledSize)
        }
        
        return processed
    }
    
    @ViewBuilder
    private func screenshotView(for deviceInfo: DeviceInfo, frameSize: CGSize, scale: CGFloat) -> some View {
        let offset = deviceInfo.offSet ?? .zero
        let scaledOffset = CGPoint(x: offset.x * scale, y: offset.y * scale)
        let processed = processedScreenshot(for: deviceInfo)
        
        let screenshotScale = scale * (deviceInfo.scaledSize != nil ? 1.0 : 1.0)
        let screenshotSize = CGSize(
            width: processed.size.width * screenshotScale,
            height: processed.size.height * screenshotScale
        )
        
        Image(uiImage: processed)
            .resizable()
            .frame(width: screenshotSize.width, height: screenshotSize.height)
            .offset(x: scaledOffset.x, y: scaledOffset.y)
            .allowsHitTesting(false)
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