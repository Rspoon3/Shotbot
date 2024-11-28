//
//  OSLogEntryLogLevel+Extension.swift.swift
//  
//
//  Created by Richard Witherspoon on 7/26/23.
//

import Foundation
import OSLog

extension OSLogEntryLog.Level {
    var title: String {
        switch self {
        case .undefined:
            return "Undefined"
        case .debug:
            return "Debug"
        case .info:
            return "Info"
        case .notice:
            return "Notice"
        case .error:
            return "Error"
        case .fault:
            return "Fault"
        @unknown default:
            return "Unknown"
        }
    }
}
