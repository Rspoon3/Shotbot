//
//  File.swift
//  
//
//  Created by Richard Witherspoon on 7/5/23.
//

import Foundation
import OSLog

/// Debug, Info, Notice, Error, Fault
///
/// Debug is not persisted, info is persisted only during "log collect", and notice, error, and fault
/// are persisted up to a storage limit.
public extension Logger {
    static let subsystem = Bundle.main.bundleIdentifier ?? "com.rspoon3.ShotbotFrames"
    
    init(category: String) {
        self.init(
            subsystem: Logger.subsystem,
            category: category
        )
    }
    
    init<T>(category type: T.Type) {
        self.init(
            subsystem: Logger.subsystem,
            category: String(describing: type)
        )
    }
}

extension Logger: @unchecked Sendable {}
