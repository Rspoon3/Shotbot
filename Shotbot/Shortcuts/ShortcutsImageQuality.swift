//
//  ShortcutsImageQuality.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 2/17/24.
//

import Foundation
import AppIntents

public enum ShortcutsImageQuality: String, AppEnum {
    case original, high, medium, low, poor
    
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Image Quality")
    public static let caseDisplayRepresentations: [ShortcutsImageQuality: DisplayRepresentation] = [
        .original: "Original",
        .high: "High",
        .medium: "Medium",
        .low: "Low",
        .poor: "Poor"
    ]
        
    public var value: Double {
        switch self {
        case .original:
            return 1.0
        case .high:
            return 0.8
        case .medium:
            return 0.6
        case .low:
            return 0.4
        case .poor:
            return 0.2
        }
    }
}
