//
//  ScreenshotTimeIntervalEntity.swift
//  Shotbot
//
//  Created by Ricky on 10/5/24.
//

import Foundation
import AppIntents

public enum ScreenshotTimeIntervalEntity: Int, CaseIterable, AppEntity {
    case latestScreenshot = 0
    case oneMinute = 1
    case fifteenMinutes = 2
    case thirtyMinutes = 3
    case sixtyMinutes = 4
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Screenshot Time Interval"
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
    
    public var title: String {
        switch self {
        case .latestScreenshot:
            return "Latest screenshot"
        case .oneMinute:
            return "1 minute"
        case .fifteenMinutes:
            return "5 minutes"
        case .thirtyMinutes:
            return "15 minutes"
        case .sixtyMinutes:
            return "60 minutes"
        }
    }
}
