//
//  DeviceDefinition.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/25/26.
//

import Foundation

/// One device as authored in the `Resources/JSON` files.
///
/// A device describes each screen's geometry and screenshot resolutions once, for its first orientation, then lists
/// the frame for each orientation. Every later orientation swaps width and height of the screen size, the screen
/// offset, and each resolution, so a phone's landscape numbers never have to be repeated.
///
/// Most devices have one screen and write it directly on the device. A device with several screens, like the
/// iPhone Duo, lists them under `displays` and shares its name and colors across all of them.
struct DeviceDefinition: Decodable, Sendable {
    /// A screenshot resolution that fits a screen.
    struct Resolution: Decodable, Sendable {
        /// What this resolution is, such as "Default", "More Space", "Display Zoom", or "Apple Spec".
        let name: String
        /// The screenshot size in pixels, in the first orientation.
        let size: CGSize
    }

    /// The frame for one orientation.
    struct Orientation: Decodable, Sendable {
        let orientation: DeviceOrientation
        /// The frame's asset name. It contains `{color}` where a color goes, for devices that come in colors.
        let frame: String
        /// Where the screen opening sits in this frame. Only needed when the frame's art is not an exact
        /// transpose of the first orientation's, which makes the swapped offset a pixel or two off.
        let offSet: CGPoint?
    }

    /// How a flat framed image is folded, for a view that is drawn by bending the display's own frame.
    struct Fold: Decodable, Sendable {
        /// The angle between the two halves in degrees, from 90 (most closed) to 180 (flat).
        let angle: Double
    }

    /// Another look of a screen, such as the iPhone Duo's outer screen open instead of closed.
    ///
    /// A view either has its own frame art (`orientations`) or bends the display's own frames (`fold`).
    struct AlternateView: Decodable, Sendable {
        /// The view's name, such as "Open" or "Partially Open".
        let name: String
        /// Where the screen opening's top-left corner sits in the view's first orientation's frame. Not needed
        /// when the view bends the display's own frames.
        let offSet: CGPoint?
        /// The view's own frames. A view only has frames for the orientations it has art for.
        let orientations: [Orientation]?
        /// Fold the display's own frames instead of using other art.
        let fold: Fold?
    }

    /// One screen of a device.
    struct Display: Decodable, Sendable {
        /// Which screen this is, such as "Inner" or "Outer". Only devices with several screens name them.
        let name: String?
        /// What the frames written on this screen show, such as "Closed", when the screen has alternate views.
        let viewName: String?
        /// The size of the frame's screen opening in pixels, in the first orientation.
        ///
        /// Only needed when screenshots are larger than the screen and get scaled down to fit. For example, a
        /// MacBook Neo screenshot is 2816 × 1762, but Apple's frame has a 2408 × 1506 screen opening. Otherwise it
        /// is the first resolution's size. See `Docs/DeviceFrames.md`.
        let screenSize: CGSize?
        /// Where the screen opening's top-left corner sits in the first orientation's frame.
        let offSet: CGPoint
        /// The screenshot resolutions that fit this screen, in its first orientation.
        let resolutions: [Resolution]
        /// The screen's frames. Phones and iPads have portrait and landscape. Watches and Macs have one.
        let orientations: [Orientation]
        /// Other looks of this screen with their own frame art, which the user can switch between.
        let alternateViews: [AlternateView]?
    }

    /// The device's display name.
    let name: String
    /// Where a color's frame draws the screen opening, for the rare color whose artwork differs from the default
    /// color's. Keyed by color name and written for the first orientation, like `offSet`.
    let colorOffsets: [String: CGPoint]?
    /// The colors the device's frame comes in, with the default first. Frame names contain `{color}`, which is
    /// replaced with each color. Devices with a single look leave this out.
    let colors: [String]?
    /// The device's screens. A device with one screen has exactly one.
    let displays: [Display]

    private enum CodingKeys: String, CodingKey {
        case name, colorOffsets, colors, displays
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        colorOffsets = try container.decodeIfPresent([String: CGPoint].self, forKey: .colorOffsets)
        colors = try container.decodeIfPresent([String].self, forKey: .colors)
        // A single-screen device writes its one screen's keys directly on the device.
        displays = try container.decodeIfPresent([Display].self, forKey: .displays) ?? [Display(from: decoder)]
    }
}
