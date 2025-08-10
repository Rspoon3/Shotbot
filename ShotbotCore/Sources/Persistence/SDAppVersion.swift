//
//  SDAppVersion.swift
//  ShotbotCore
//
//  Created by Claude Code on 8/10/25.
//

import Foundation
import SwiftData

@Model
public class SDAppVersion {
    public var major: Int
    public var minor: Int
    public var patch: Int
    public var build: Int
    public var createdAt: Date
    
    @Attribute(.unique) public var rawVersion: String
    
    @Relationship(deleteRule: .cascade, inverse: \SDAnalyticEvent.appVersion)
    public var analyticsEvents: [SDAnalyticEvent] = []
    
    public init() {
        let versionString = Bundle.appVersion ?? "0.0.0"
        let components = versionString.split(separator: ".").compactMap { Int($0) }
        
        self.major = components.count > 0 ? components[0] : 0
        self.minor = components.count > 1 ? components[1] : 0
        self.patch = components.count > 2 ? components[2] : 0
        
        self.rawVersion = versionString
        self.build = Int(Bundle.appBuild ?? "0") ?? 0
        self.createdAt = .now
    }
    
    public static func firstDate(
        versionAtOrAbove versionString: String,
        modelContext: ModelContext
    ) throws -> Date? {
        let components = versionString.split(separator: ".").map { Int($0) ?? 0 }
        let major = components.count > 0 ? components[0] : 0
        let minor = components.count > 1 ? components[1] : 0
        let patch = components.count > 2 ? components[2] : 0
        
        let predicate = #Predicate<SDAppVersion> { version in
            version.major > major ||
            (version.major == major && version.minor > minor) ||
            (version.major == major && version.minor == minor && version.patch >= patch)
        }
        
        var descriptor = FetchDescriptor<SDAppVersion>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        descriptor.fetchLimit = 1
        
        let results = try modelContext.fetch(descriptor)
        return results.first?.createdAt
    }
    
    public static func legacy(modelContext: ModelContext) -> SDAppVersion {
        let version = SDAppVersion()
        version.major = -1
        version.minor = 0
        version.patch = 0
        version.build = 0
        version.rawVersion = "legacy"
        version.createdAt = .distantPast
        
        modelContext.insert(version)
        return version
    }
    
}
