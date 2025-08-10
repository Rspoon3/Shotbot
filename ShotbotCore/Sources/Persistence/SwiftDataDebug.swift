//
//  SwiftDataDebug.swift
//  ShotbotCore
//
//  Created by Claude Code on 8/10/25.
//

#if DEBUG
import Foundation
import SwiftData
import SQLite3

public struct SwiftDataDebugEntity: Identifiable {
    public let id = UUID()
    public let entityName: String
    public let objects: [SwiftDataDebugObject]
    
    public init(
        entityName: String,
        objects: [SwiftDataDebugObject]
    ) {
        self.entityName = entityName
        self.objects = objects
    }
}

public struct SwiftDataDebugObject: Identifiable {
    public let id = UUID()
    public let attributes: [String: Any]
    public let persistentModelID: PersistentIdentifier?
    
    public init(
        attributes: [String: Any],
        persistentModelID: PersistentIdentifier?
    ) {
        self.attributes = attributes
        self.persistentModelID = persistentModelID
    }
}

extension ModelContext {
    @MainActor public func fetchSwiftDataDebugData() throws -> [SwiftDataDebugEntity] {
        // Use the new protocol-based approach for automatic discovery
        return try fetchAllIndexableData()
    }
}
#endif
