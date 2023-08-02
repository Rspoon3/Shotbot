//
//  OSLogStore+Extension.swift
//  
//
//  Created by Richard Witherspoon on 7/26/23.
//

import Foundation
import OSLog
import Models

extension OSLogStore {
    func generateLogAttachments(startDate: Date) async throws -> [SBLog] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: SBError.noSelf)
                    return
                }
                
                let position = self.position(date: startDate)
                
                do {
                  let fetchLogs = try self
                        .getEntries(at: position)
                        .compactMap { $0 as? OSLogEntryLog }
                        .filter { $0.subsystem == Logger.subsystem }
                        .sorted(by: {$0.date < $1.date})
                        .map { SBLog(osLog: $0) }
                    
                  continuation.resume(returning: fetchLogs)
                } catch {
                  continuation.resume(throwing: error)
                }
            }
        }
    }
}
