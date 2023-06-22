//
//  ImageQuality.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 5/20/23.
//

import Foundation
import AppIntents

public enum ImageQuality: String, CaseIterable, Identifiable {
    case original = "Original"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    case poor = "Poor"
    
    public var id: String { rawValue }
    
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

extension ImageQuality: AppEnum {
    public static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "ImageQuality")
    public static var typeDisplayName: LocalizedStringResource = "Image Quality"
    
    public static var caseDisplayRepresentations: [ImageQuality: DisplayRepresentation] = [
        .original: "Original",
        .high: "High",
        .medium: "Medium",
        .low: "Low",
        .poor: "Poor"
    ]
}
