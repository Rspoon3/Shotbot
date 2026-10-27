//
//  CanvasAspect.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import Foundation

/// The shape of the finished picture. Devices are centered in it, and the background fills what's left over.
enum CanvasAspect: String, CaseIterable, Identifiable, Sendable {
    /// Just big enough for the devices and a margin.
    case fit
    case square
    case story
    case landscape
    case instagram

    var id: String { rawValue }

    /// The label on the picker.
    var title: String {
        switch self {
        case .fit: "Fit"
        case .square: "Square"
        case .story: "9:16"
        case .landscape: "16:9"
        case .instagram: "Instagram"
        }
    }

    /// Width divided by height, or `nil` when the picture takes whatever shape the devices need.
    var ratio: Double? {
        switch self {
        case .fit: nil
        case .square: 1
        case .story: 9.0 / 16.0
        case .landscape: 16.0 / 9.0
        case .instagram: 4.0 / 5.0
        }
    }
}
