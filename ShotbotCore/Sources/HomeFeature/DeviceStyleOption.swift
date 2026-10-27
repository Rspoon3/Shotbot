//
//  DeviceStyleOption.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/26/26.
//

import Foundation

/// The frame choices available for one device in the current screenshots: its colors and its views.
public struct DeviceStyleOption: Identifiable, Equatable, Sendable {
    /// The device's display name, such as "iPhone 17 Pro".
    public let deviceName: String
    /// Every color the device's frame comes in, with the default first. Empty when it has one look.
    public let colors: [String]
    /// The color currently used for the device's frames.
    public let selectedColor: String?
    /// Every view the device's frame has, with the default first, such as "Closed" and "Open". Empty when it has one.
    public let views: [String]
    /// The view currently used for the device's frames.
    public let selectedView: String?

    public var id: String { deviceName }

    /// Whether there is more than one color to choose from.
    public var hasColors: Bool { colors.count > 1 }

    /// Whether there is more than one view to choose from.
    public var hasViews: Bool { views.count > 1 }
}
