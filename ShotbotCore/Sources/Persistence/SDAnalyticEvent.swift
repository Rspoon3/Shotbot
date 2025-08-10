//
//  SDAnalyticEvent.swift
//  ShotbotCore
//
//  Created by Claude Code on 8/10/25.
//

import Foundation
import SwiftData

@Model
public class SDAnalyticEvent: SwiftDataIndexable {
    public var name: String
    public var createdAt: Date
    
    @Relationship
    public var appVersion: SDAppVersion
    
    public init(
        event: AnalyticEvent,
        appVersion: SDAppVersion
    ) {
        self.name = event.rawValue
        self.appVersion = appVersion
        self.createdAt = .now
    }
    
    public init(
        legacyEvent: AnalyticEvent,
        legacyAppVersionRecord: SDAppVersion
    ) {
        self.name = legacyEvent.rawValue
        self.appVersion = legacyAppVersionRecord
        self.createdAt = .distantPast
    }
    
    public static func totalCount(
        for event: AnalyticEvent,
        modelContext: ModelContext
    ) throws -> Int {
        let eventTitle = event.rawValue
        let predicate = #Predicate<SDAnalyticEvent> { analyticEvent in
            analyticEvent.name == eventTitle
        }
        
        let descriptor = FetchDescriptor<SDAnalyticEvent>(predicate: predicate)
        let results = try modelContext.fetch(descriptor)
        return results.count
    }
    
    public static func count(
        fromVersion versionString: String,
        for event: AnalyticEvent,
        modelContext: ModelContext
    ) throws -> Int {
        let components = versionString.split(separator: ".").map { Int($0) ?? 0 }
        let major = components.count > 0 ? components[0] : 0
        let minor = components.count > 1 ? components[1] : 0
        let patch = components.count > 2 ? components[2] : 0
        let eventTitle = event.rawValue

        let predicate = #Predicate<SDAnalyticEvent> { analyticEvent in
            analyticEvent.name == eventTitle &&
            (analyticEvent.appVersion.major > major ||
             (analyticEvent.appVersion.major == major && analyticEvent.appVersion.minor > minor) ||
             (analyticEvent.appVersion.major == major && analyticEvent.appVersion.minor == minor && analyticEvent.appVersion.patch >= patch))
        }

        let descriptor = FetchDescriptor<SDAnalyticEvent>(predicate: predicate)
        let results = try modelContext.fetch(descriptor)
        return results.count
    }
}

#if DEBUG
extension SDAnalyticEvent {
    public func debugAttributes() -> [String: Any] {
        return [
            "name": name,
            "createdAt": createdAt,
            "appVersion": "\(appVersion.rawVersion) (\(appVersion.build))"
        ]
    }
}
#endif
