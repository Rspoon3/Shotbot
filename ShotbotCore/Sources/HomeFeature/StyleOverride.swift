//
//  StyleOverride.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/26/26.
//

import Models

/// The color and view picked for a single screenshot, which win over the choice for all of them.
struct StyleOverride: Equatable, Sendable {
    /// The color picked for this screenshot, or `nil` to use the choice for the device.
    var color: String?
    /// The view picked for this screenshot, or `nil` to use the choice for the screen.
    var view: String?

    /// Whether nothing was picked for this screenshot.
    var isEmpty: Bool {
        color == nil && view == nil
    }

    /// The device with this screenshot's own choices applied on top of whatever it already has.
    func applied(to device: DeviceInfo) -> DeviceInfo {
        var styled = device

        if let color {
            styled = styled.withColor(color)
        }

        if let view {
            styled = styled.withView(view)
        }

        return styled
    }
}
