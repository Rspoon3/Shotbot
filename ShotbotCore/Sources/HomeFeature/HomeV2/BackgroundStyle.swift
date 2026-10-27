//
//  BackgroundStyle.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import Foundation

/// A background that can be drawn behind framed devices at any size.
enum BackgroundStyle: String, CaseIterable, Identifiable, Sendable {
    case transparent
    case white
    case black
    case sunset
    case ocean
    case aurora
    case blurred

    var id: String { rawValue }

    /// A short name for accessibility and labels.
    var title: String {
        switch self {
        case .transparent: "None"
        case .white: "White"
        case .black: "Black"
        case .sunset: "Sunset"
        case .ocean: "Ocean"
        case .aurora: "Aurora"
        case .blurred: "Blurred"
        }
    }
}
