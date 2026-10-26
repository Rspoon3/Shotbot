//
//  DeviceStyleOption.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/26/26.
//

import Foundation

/// The frame choices available for one device in the current screenshots: its colors, and the views of each screen.
public struct DeviceStyleOption: Identifiable, Equatable, Sendable {
    /// The views one screen of the device can be shown in, such as the iPhone Duo's inner screen flat or partially open.
    public struct Screen: Identifiable, Equatable, Sendable {
        /// Which screen this is, such as "Inner". `nil` for a device with one screen.
        public let screenName: String?
        /// What the saved choice is keyed by, which is `DeviceInfo.viewPreferenceKey`.
        public let viewKey: String
        /// Every view the screen has, with the default first.
        public let views: [String]
        /// The view currently used for the screen's frames.
        public let selectedView: String

        public var id: String { viewKey }
    }

    /// The device's display name, such as "iPhone 17 Pro".
    public let deviceName: String
    /// Every color the device's frame comes in, with the default first. Empty when it has one look.
    public let colors: [String]
    /// The color currently used for the device's frames.
    public let selectedColor: String?
    /// The screens that have more than one view.
    public let screens: [Screen]

    public var id: String { deviceName }

    /// Whether there is more than one color to choose from.
    public var hasColors: Bool { colors.count > 1 }
}
