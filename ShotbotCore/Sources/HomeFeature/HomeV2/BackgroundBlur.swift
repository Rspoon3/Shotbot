//
//  BackgroundBlur.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import Foundation

/// How much a photo background is blurred.
enum BackgroundBlur: String, CaseIterable, Identifiable, Sendable {
    case none
    case light
    case medium
    case strong

    var id: String { rawValue }

    /// The label on the picker.
    var title: String {
        switch self {
        case .none: "None"
        case .light: "Light"
        case .medium: "Medium"
        case .strong: "Strong"
        }
    }

    /// The Gaussian blur radius as a fraction of the picture's height, so a blur looks the same at any size.
    var strength: Double {
        switch self {
        case .none: 0
        case .light: 0.006
        case .medium: 0.018
        case .strong: 0.045
        }
    }
}
