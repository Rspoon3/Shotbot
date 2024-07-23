//
//  DurationWidgetOption.swift
//  WidgetsExtension
//
//  Created by Richard Witherspoon on 7/20/24.
//

import Foundation

enum DurationWidgetOption: Int, CaseIterable, Identifiable {
    case oneMinute = 0
    case fifteenMinutes = 1
    case thirtyMinutes = 2
    case sixtyMinutes = 3
    
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .oneMinute:
            return "1m"
        case .fifteenMinutes:
            return "15m"
        case .thirtyMinutes:
            return "30m"
        case .sixtyMinutes:
            return "60m"
        }
    }
}
