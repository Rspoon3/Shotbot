//
//  DeviceColorOption.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/26/26.
//

import Foundation

/// The frame colors available for one device in the current screenshots.
public struct DeviceColorOption: Identifiable, Equatable, Sendable {
    /// The device's display name, such as "iPhone 17 Pro".
    public let deviceName: String
    /// Every color the device's frame comes in, with the default first.
    public let colors: [String]
    /// The color currently used for the device's frames.
    public let selectedColor: String

    public var id: String { deviceName }
}
