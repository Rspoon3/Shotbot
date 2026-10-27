//
//  SceneRecipe.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import Foundation

/// Everything that decides how framed devices are laid out and dressed, apart from the devices themselves.
///
/// All sizes are fractions of the device's height, so the same recipe gives the same picture at any resolution.
struct SceneRecipe: Equatable, Sendable {
    /// What is drawn behind the devices.
    var background: BackgroundStyle = .sunset
    /// The space around the devices, as a fraction of their height.
    var padding: Double = 0.08
    /// Whether the devices cast a soft shadow on the background.
    var hasShadow = true
}
