//
//  DeviceInfo.swift
//  Testing
//
//  Created by Richard Witherspoon on 4/19/23.
//

import UIKit
import SwiftTools

public struct DeviceInfo: Decodable, Sendable {
    public let deviceFrame: String
    public let mergeMethod: MergeMethod
    public let clipEdgesAmount: CGFloat?
    public let cornerRadius: CGFloat?
    public let inputSize: CGSize
    public let scaledSize: CGSize?
    public let offSet: CGPoint?

    /// The screenshot resolution produced when Display Zoom is enabled on this device.
    /// When present, this resolution may collide with another device's native `inputSize`.
    public let displayZoomInputSize: CGSize?

    // MARK: - Initializer

    public init(
        deviceFrame: String,
        mergeMethod: MergeMethod,
        clipEdgesAmount: CGFloat?,
        cornerRadius: CGFloat?,
        inputSize: CGSize,
        scaledSize: CGSize?,
        offSet: CGPoint?,
        displayZoomInputSize: CGSize? = nil
    ) {
        self.deviceFrame = deviceFrame
        self.mergeMethod = mergeMethod
        self.clipEdgesAmount = clipEdgesAmount
        self.inputSize = inputSize
        self.scaledSize = scaledSize
        self.offSet = offSet
        self.cornerRadius = cornerRadius
        self.displayZoomInputSize = displayZoomInputSize
    }
    
    /// A user-friendly device name extracted from the frame identifier.
    ///
    /// Strips orientation and color suffixes:
    /// - "iPhone Air - Space Black - Portrait" → "iPhone Air"
    /// - "iPhone 11 Pro Portrait" → "iPhone 11 Pro"
    public var displayName: String {
        var name = deviceFrame
            .components(separatedBy: " - ")
            .first?
            .trimmingCharacters(in: .whitespaces) ?? deviceFrame

        for suffix in [" Portrait", " Landscape"] {
            if name.hasSuffix(suffix) {
                name = String(name.dropLast(suffix.count))
            }
        }

        return name
    }

    /// The device frame asset image, if available.
    public var frameImage: UIImage? {
        UIImage(named: deviceFrame, in: .module, with: nil)
    }

    // MARK: - Functions

    public func framed(using screenshot: UIImage) -> UIImage? {
        var screenshot = screenshot
        let offSet = offSet ?? .zero
        
        guard let frameImage = UIImage(named: deviceFrame, in: .module, with: nil) else {
            return nil
        }
        
        if let clipEdgesAmount {
            screenshot = screenshot.clipEdges(amount: clipEdgesAmount)
        } else if let cornerRadius {
            screenshot = screenshot.withRoundedCorners(radius: cornerRadius)
        }
        
        if let scaledSize {
            screenshot = screenshot.resized(to: scaledSize)
        }
        
        switch mergeMethod {
        case .singleOverlay:
            return frameImage.merge(with: screenshot, offset: offSet)
        case .singleOverlayV2:
            return screenshot.overlayWithLargerCenteredImage(frameImage)
        case .doubleOverlay:
            let image = frameImage.merge(with: screenshot, offset: offSet)
            return image.merge(with: frameImage, offset: .zero)
        case .islandOverlay:
            guard let noIsland = UIImage(named: "\(deviceFrame) Without Island", in: .module, with: nil) else {
                return nil
            }
            
            let noIslandFrame = noIsland.merge(with: screenshot, offset: offSet)
            
            return noIslandFrame.merge(with: frameImage, offset: .zero)
        }
    }
    
    // MARK: - Data
    
    public static func all() -> [DeviceInfo] {
        let bundle = Bundle.module

        let iPhoneFrames = try! bundle.decode([DeviceInfo].self, from: "iPhoneFrames.json")
        let iPadFrames = try! bundle.decode([DeviceInfo].self, from: "iPadFrames.json")
        let macFrames = try! bundle.decode([DeviceInfo].self, from: "MacFrames.json")
        let AppleWatchFrames = try! bundle.decode([DeviceInfo].self, from: "AppleWatchFrames.json")

        return iPhoneFrames + iPadFrames + macFrames + AppleWatchFrames
    }

    /// Matches a screenshot size against all known devices, accounting for Display Zoom.
    ///
    /// Returns `.ambiguous` when the size matches both a device's native `inputSize`
    /// and another device's `displayZoomInputSize`, requiring user disambiguation.
    public static func match(for screenshotSize: CGSize) -> DeviceMatchResult {
        let devices = all()
        var matches: [DeviceInfo] = []

        // Check direct inputSize matches
        if let direct = devices.first(where: { $0.inputSize == screenshotSize }) {
            matches.append(direct)
        }

        // Check display zoom matches — create a synthetic DeviceInfo with scaledSize
        // so the existing framed(using:) method resizes the zoomed screenshot to native
        for device in devices where device.displayZoomInputSize == screenshotSize {
            let zoomDevice = DeviceInfo(
                deviceFrame: device.deviceFrame,
                mergeMethod: device.mergeMethod,
                clipEdgesAmount: device.clipEdgesAmount,
                cornerRadius: device.cornerRadius,
                inputSize: screenshotSize,
                scaledSize: device.inputSize,
                offSet: device.offSet
            )
            matches.append(zoomDevice)
        }

        switch matches.count {
        case 0: return .none
        case 1: return .exact(matches[0])
        default: return .ambiguous(matches)
        }
    }
}

/// The result of matching a screenshot's dimensions against known device configurations.
public enum DeviceMatchResult {
    /// Exactly one device matches the screenshot size.
    case exact(DeviceInfo)
    /// Multiple devices claim this resolution (e.g., native + display zoom conflict).
    case ambiguous([DeviceInfo])
    /// No known device matches this screenshot size.
    case none
}
