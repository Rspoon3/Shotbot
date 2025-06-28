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
    
    public var body: some View {
        if let deviceInfo, let frameImage {
            ZStack {
                // Screenshot layer (positioned using device info)
                screenshotView(for: deviceInfo, frameImage: frameImage)
                
                // Frame overlay
                Image(uiImage: frameImage)
                    .resizable()
                    .scaledToFit()
                    .allowsHitTesting(false)
                    .opacity(0.7)
            }
            .frame(
                maxWidth: frameSize.width / displayScale,
                maxHeight: frameSize.height / displayScale
            )
            .aspectRatio(frameImage.size, contentMode: .fit)
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
    private func screenshotView(for deviceInfo: DeviceInfo, frameImage: UIImage) -> some View {
        GeometryReader { geometry in
            let processed = processedScreenshot(for: deviceInfo)
            
            // Calculate the scale factor for the frame to fit in the view
            let frameScale = min(
                geometry.size.width / frameImage.size.width,
                geometry.size.height / frameImage.size.height
            )
            
            // Calculate screenshot size
            let screenshotSize = CGSize(
                width: processed.size.width * frameScale,
                height: processed.size.height * frameScale
            )
            
            // Check if this is a landscape frame (width > height)
            let isLandscape = frameImage.size.width > frameImage.size.height
            
            var positionX: CGFloat
            let positionY: CGFloat
            
            if isLandscape {
                positionX = frameScale + screenshotSize.width / 2
                positionY = frameScale + screenshotSize.height / 2
            } else {
                // Portrait positioning - centered with offset
                let centerX = geometry.size.width / 2
                let centerY = geometry.size.height / 2
                positionX = centerX + frameScale
                positionY = centerY + frameScale
            }
            
            return Image(uiImage: processed)
                .resizable()
                .frame(width: screenshotSize.width, height: screenshotSize.height)
                .position(x: positionX, y: positionY)
                .allowsHitTesting(false)
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
