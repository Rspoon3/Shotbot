//
//  SBLog.swift
//  
//
//  Created by Richard Witherspoon on 7/26/23.
//

import Foundation
import OSLog

/// An identifiable and constructible wrapper for OSLogEntryLog
struct SBLog: Identifiable, Equatable, Hashable, Sendable {
    let id = UUID()
    let date: Date
    let category: String
    let level: OSLogEntryLog.Level
    let message: String
    
    var text: String {
        let formattedDate = date.formatted(.log)
        
        return "\(formattedDate), \(category), \(level.title), \(message)"
    }
    
    // MARK: - Initializer
    
    init(
        date: Date,
        category: String,
        level: OSLogEntryLog.Level,
        message: String
    ) {
        self.date = date
        self.category = category
        self.level = level
        self.message = message
    }
    
    init(osLog: OSLogEntryLog) {
        self.date = osLog.date
        self.category = osLog.category
        self.level = osLog.level
        self.message = osLog.composedMessage
    }
}
