//
//  ImageQuality+Extension.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 6/22/23.
//

import Foundation
import Models
import AppIntents

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
