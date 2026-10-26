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
    /// One look of a device's frame: the frame art and where it draws the screen.
    private struct ViewFrame: Sendable {
        /// The frame's asset name with `{color}` where the color goes.
        let frameTemplate: String
        /// Where the default color's frame draws the screen opening.
        let offSet: CGPoint
        /// Where a color's frame draws the screen, for colors that differ from the default. Already swapped for landscape.
        let colorOffsets: [String: CGPoint]
        /// The asset name the screen mask is stored under, which is always the default color's frame.
        let maskName: String
    }

    /// The display name of the device model, such as "iPhone 16 Pro".
    public let name: String
    /// Which screen this frame is for, such as "Inner" or "Outer", for devices with several. `nil` for one screen.
    public let screenName: String?
    /// Which way the device is held in this frame.
    public let orientation: DeviceOrientation
    /// The colors this device's frame comes in, with the default first. Empty when it has a single look.
    public let colors: [String]
    /// The selected color, or `nil` when the device has a single look.
    public private(set) var colorName: String?
    /// The views of this screen that have a frame in this orientation, with the default first, such as "Closed" and
    /// "Open" for the iPhone Duo's outer screen. Empty when the screen has only one.
    public let views: [String]
    /// The selected view, or `nil` when the screen has only one.
    public private(set) var viewName: String?
    /// The key of the default view in `viewFrames`.
    private let defaultViewName: String
    /// The frame for each view.
    private let viewFrames: [String: ViewFrame]
    /// The screenshot size this entry matches.
    public let inputSize: CGSize
    /// The size of the frame's screen opening. Screenshots with a different `inputSize` are scaled to this.
    public let screenSize: CGSize
    /// What kind of resolution this is, such as "Default", "More Space", or "Display Zoom".
    public let resolutionName: String

    /// The frame's asset name, for the selected view and color.
    public var deviceFrame: String {
        Self.resolve(viewFrame.frameTemplate, color: colorName)
    }

    /// Where the screen opening's top-left corner sits in the frame.
    public var offSet: CGPoint {
        colorName.flatMap { viewFrame.colorOffsets[$0] } ?? viewFrame.offSet
    }

    private var viewFrame: ViewFrame {
        viewFrames[viewName ?? defaultViewName] ?? viewFrames[defaultViewName]!
    }

    private static let allDevices: [DeviceInfo] = {
        let bundle = Bundle.module
        let fileNames = ["iPhoneFrames.json", "iPadFrames.json", "MacFrames.json", "AppleWatchFrames.json"]

        return fileNames
            .flatMap { try! bundle.decode([DeviceDefinition].self, from: $0) }
            .flatMap(expand)
    }()

    // MARK: - Initializer

    private init(
        name: String,
        screenName: String?,
        orientation: DeviceOrientation,
        colors: [String],
        views: [String],
        defaultViewName: String,
        viewFrames: [String: ViewFrame],
        inputSize: CGSize,
        screenSize: CGSize,
        resolutionName: String
    ) {
        self.name = name
        self.screenName = screenName
        self.orientation = orientation
        self.colors = colors
        self.colorName = colors.first
        self.views = views
        self.viewName = views.first
        self.defaultViewName = defaultViewName
        self.viewFrames = viewFrames
        self.inputSize = inputSize
        self.screenSize = screenSize
        self.resolutionName = resolutionName
    }

    // MARK: - Public Helpers

    /// Whether the device's frame comes in more than one color.
    public var hasColorOptions: Bool {
        colors.count > 1
    }

    /// Whether the screen has more than one view in this orientation.
    public var hasViewOptions: Bool {
        views.count > 1
    }

    /// The same device in another color.
    /// - Parameter color: One of `colors`. An unknown color returns the device unchanged.
    public func withColor(_ color: String) -> DeviceInfo {
        guard colors.contains(color) else { return self }

        var copy = self
        copy.colorName = color
        return copy
    }

    /// The same device in another view, such as the iPhone Duo's outer screen open instead of closed.
    /// - Parameter view: One of `views`. An unknown view returns the device unchanged.
    public func withView(_ view: String) -> DeviceInfo {
        guard views.contains(view) else { return self }

        var copy = self
        copy.viewName = view
        return copy
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
    /// `nil` for a frame with no enclosed screen to mask.
    public var screenMask: CGImage? {
        ScreenMaskCache.mask(for: viewFrame.maskName)
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

    /// Every device resolution Shotbot can frame, in each device's default color and view.
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

    // MARK: - Private Helpers

    private static func resolve(_ template: String, color: String?) -> String {
        guard let color else { return template }
        return template.replacingOccurrences(of: "{color}", with: color)
    }

    /// Expands a device definition into one entry per screen, orientation and resolution.
    private static func expand(_ definition: DeviceDefinition) -> [DeviceInfo] {
        let colors = definition.colors ?? []

        return definition.displays.flatMap { display in
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

                // The default view is the frame written on the display. Alternate views add their own frames,
                // but only in the orientations they have art for.
                let defaultViewName = display.viewName ?? "Default"
                var viewFrames = [
                    defaultViewName: ViewFrame(
                        frameTemplate: orientation.frame,
                        offSet: offSet,
                        colorOffsets: colorOffsets,
                        maskName: resolve(orientation.frame, color: colors.first)
                    )
                ]
                var views = [String]()

                for alternate in display.alternateViews ?? [] {
                    guard let alternateIndex = alternate.orientations.firstIndex(where: { $0.orientation == orientation.orientation }) else {
                        continue
                    }

                    let alternateFrame = alternate.orientations[alternateIndex]
                    viewFrames[alternate.name] = ViewFrame(
                        frameTemplate: alternateFrame.frame,
                        offSet: alternateFrame.offSet
                            ?? (alternateIndex > 0 ? CGPoint(x: alternate.offSet.y, y: alternate.offSet.x) : alternate.offSet),
                        colorOffsets: [:],
                        maskName: resolve(alternateFrame.frame, color: colors.first)
                    )
                    views.append(alternate.name)
                }

                return display.resolutions.map { resolution in
                    DeviceInfo(
                        name: definition.name,
                        screenName: display.name,
                        orientation: orientation.orientation,
                        colors: colors,
                        views: views.isEmpty ? [] : [defaultViewName] + views,
                        defaultViewName: defaultViewName,
                        viewFrames: viewFrames,
                        inputSize: swapped ? resolution.size.swapped : resolution.size,
                        screenSize: screenSize,
                        resolutionName: resolution.name
                    )
                }
            }
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
