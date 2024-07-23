//
//  DurationWidgetOption.swift
//
//
//  Created by Richard Witherspoon on 7/22/24.
//

import Foundation

public enum DurationWidgetOption: Int, CaseIterable, Identifiable {
    case oneMinute = 0
    case fifteenMinutes = 1
    case thirtyMinutes = 2
    case sixtyMinutes = 3
    
    private struct Info {
        let title: String
        let dateComponent: Calendar.Component
        let dateValue: Int
    }
    
    public var id: Int { rawValue }
    public var title: String { info.title }
    public var dateComponent: Calendar.Component { info.dateComponent }
    public var dateValue: Int { info.dateValue }
    
    private var info: Info {
        switch self {
        case .oneMinute:
            return Info(title: "1m", dateComponent: .minute, dateValue: 1)
        case .fifteenMinutes:
            return Info(title: "15m", dateComponent: .minute, dateValue: 5)
        case .thirtyMinutes:
            return Info(title: "15m", dateComponent: .minute, dateValue: 15)
        case .sixtyMinutes:
            return Info(title: "60m", dateComponent: .minute, dateValue: 60)
        }
    }
}
