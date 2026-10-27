//
//  DeviceInfo.swift
//  Testing
//
//  Created by Richard Witherspoon on 4/19/23.
//

import UIKit
import SwiftTools

/// A device frame paired with one screenshot resolution that fits it.
///
/// Every frame goes through the same steps: scale the screenshot to the screen opening if its
/// resolution differs, clip it to the frame's screen mask if one is bundled, place it at `offSet`
/// on a transparent canvas, then draw the frame on top.
public struct DeviceInfo: Sendable {
    /// The display name of the device model, such as "iPhone 16 Pro".
    public let name: String
    /// Which screen this frame is for, such as "Inner" or "Outer", for devices with several. `nil` for one screen.
    public let screenName: String?
    /// Which way the device is held in this frame.
    public let orientation: DeviceOrientation
    /// The frame's asset name, for the selected color.
    public let deviceFrame: String
    /// The colors this device's frame comes in, with the default first. Empty when it has a single look.
    public let colors: [String]
    /// The selected color, or `nil` when the device has a single look.
    public let colorName: String?
    /// The frame's asset name with `{color}` where the color goes.
    private let frameTemplate: String
    /// The asset name the screen mask is stored under, which is always the default color's frame.
    private let maskName: String
    /// Where each color's frame draws the screen, for colors that differ from the default. Already swapped for landscape.
    private let colorOffsets: [String: CGPoint]
    /// Where the default color's frame draws the screen.
    private let defaultOffSet: CGPoint
    /// The screenshot size this entry matches.
    public let inputSize: CGSize
    /// The size of the frame's screen opening. Screenshots with a different `inputSize` are scaled to this.
    public let screenSize: CGSize
    /// Where the screen opening's top-left corner sits in the frame.
    public let offSet: CGPoint
    /// What kind of resolution this is, such as "Default", "More Space", or "Display Zoom".
    public let resolutionName: String

    private static let allDevices: [DeviceInfo] = {
        let bundle = Bundle.module
        let fileNames = ["iPhoneFrames.json", "iPadFrames.json", "MacFrames.json", "AppleWatchFrames.json"]

        return fileNames
            .flatMap { try! bundle.decode([DeviceDefinition].self, from: $0) }
            .flatMap { definition in
                definition.displays.flatMap { display in
                    display.orientations.enumerated().flatMap { index, orientation in
                        // The first orientation is written as authored; later ones swap width and height.
                        let swapped = index > 0
                        let nativeScreenSize = display.screenSize ?? display.resolutions[0].size
                        let screenSize = swapped ? nativeScreenSize.swapped : nativeScreenSize
                        let offSet = orientation.offSet
                            ?? (swapped ? CGPoint(x: display.offSet.y, y: display.offSet.x) : display.offSet)

                        let colorOffsets = (definition.colorOffsets ?? [:]).mapValues {
                            swapped ? CGPoint(x: $0.y, y: $0.x) : $0
                        }
                        let colors = definition.colors ?? []
                        let defaultFrame = colors.first.map { orientation.frame.replacingOccurrences(of: "{color}", with: $0) }
                            ?? orientation.frame

                        return display.resolutions.map { resolution in
                            DeviceInfo(
                                name: definition.name,
                                screenName: display.name,
                                orientation: orientation.orientation,
                                deviceFrame: defaultFrame,
                                colors: colors,
                                colorName: colors.first,
                                frameTemplate: orientation.frame,
                                maskName: defaultFrame,
                                colorOffsets: colorOffsets,
                                defaultOffSet: offSet,
                                inputSize: swapped ? resolution.size.swapped : resolution.size,
                                screenSize: screenSize,
                                offSet: offSet,
                                resolutionName: resolution.name
                            )
                        }
                    }
                }
            }
    }()

    // MARK: - Initializer

    public init(
        name: String,
        screenName: String? = nil,
        orientation: DeviceOrientation,
        deviceFrame: String,
        colors: [String] = [],
        colorName: String? = nil,
        frameTemplate: String? = nil,
        maskName: String? = nil,
        colorOffsets: [String: CGPoint] = [:],
        defaultOffSet: CGPoint? = nil,
        inputSize: CGSize,
        screenSize: CGSize,
        offSet: CGPoint,
        resolutionName: String = "Default"
    ) {
        self.name = name
        self.screenName = screenName
        self.orientation = orientation
        self.deviceFrame = deviceFrame
        self.colors = colors
        self.colorName = colorName
        self.frameTemplate = frameTemplate ?? deviceFrame
        self.maskName = maskName ?? deviceFrame
        self.colorOffsets = colorOffsets
        self.defaultOffSet = defaultOffSet ?? offSet
        self.inputSize = inputSize
        self.screenSize = screenSize
        self.offSet = offSet
        self.resolutionName = resolutionName
    }

    // MARK: - Public Helpers

    /// Whether the device's frame comes in more than one color.
    public var hasColorOptions: Bool {
        colors.count > 1
    }

    /// The same device in another color.
    /// - Parameter color: One of `colors`. An unknown color returns the device unchanged.
    public func withColor(_ color: String) -> DeviceInfo {
        guard colors.contains(color) else { return self }

        return DeviceInfo(
            name: name,
            screenName: screenName,
            orientation: orientation,
            deviceFrame: frameTemplate.replacingOccurrences(of: "{color}", with: color),
            colors: colors,
            colorName: color,
            frameTemplate: frameTemplate,
            maskName: maskName,
            colorOffsets: colorOffsets,
            defaultOffSet: defaultOffSet,
            inputSize: inputSize,
            screenSize: screenSize,
            offSet: colorOffsets[color] ?? defaultOffSet,
            resolutionName: resolutionName
        )
    }

    /// Whether screenshots at `inputSize` are scaled to fit the frame's screen opening.
    public var isScaled: Bool {
        inputSize != screenSize
    }

    /// A user-friendly device name, such as "iPhone 16 Pro".
    public var displayName: String {
        name
    }

    /// The device frame asset image, if available.
    public var frameImage: UIImage? {
        UIImage(named: deviceFrame, in: .module, with: nil)
    }

    /// The bundled screen mask for this frame, cropped to the screen opening.
    ///
    /// `nil` for frames whose bezel is never fully opaque, such as Studio Display, which have no mask.
    public var screenMask: CGImage? {
        ScreenMaskCache.mask(for: maskName)
    }

    /// Frames a screenshot.
    /// - Parameter screenshot: A screenshot at `inputSize`.
    /// - Returns: The screenshot inside the device frame on a transparent background.
    public func framed(using screenshot: UIImage) -> UIImage? {
        guard let frameImage else { return nil }

        let screen = isScaled ? screenshot.resized(to: screenSize) : screenshot

        return frameImage.overlaying(screen, at: offSet, clippedTo: screenMask)
    }

    // MARK: - Data

    /// Every device resolution Shotbot can frame.
    public static func all() -> [DeviceInfo] {
        allDevices
    }

    /// Matches a screenshot size against all known device resolutions.
    ///
    /// Returns `.ambiguous` when more than one device claims the size, such as the iPhone 16 Pro, 17, 17 Pro and 18 Pro,
    /// which all take 1206 × 2622 screenshots, or a Display Zoom resolution that equals another phone's native
    /// resolution. The user then picks the device.
    ///
    /// When nothing matches exactly, sizes within a pixel of a known resolution match. A few alternate resolutions,
    /// like a Mac's "More Space" mode, are scaled from a size whose height is rounded.
    public static func match(for screenshotSize: CGSize) -> DeviceMatchResult {
        var matches = allDevices.filter { $0.inputSize == screenshotSize }

        if matches.isEmpty {
            matches = allDevices.filter {
                abs($0.inputSize.width - screenshotSize.width) <= 1 && abs($0.inputSize.height - screenshotSize.height) <= 1
            }
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
