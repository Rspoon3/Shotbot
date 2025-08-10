//
//  SwiftDataIndexable.swift
//  ShotbotCore
//
//  Created by Claude Code on 8/10/25.
//

#if DEBUG
import Foundation
import SwiftData

/// Protocol that makes any SwiftData model automatically discoverable and debuggable
public protocol SwiftDataIndexable: PersistentModel {
    /// The name to display in debug views (defaults to the type name)
    static var debugDisplayName: String { get }
    /// Extract readable attributes for debugging (defaults to reflection-based extraction)
    func debugAttributes() -> [String: Any]
}

// MARK: - Default Implementation

extension SwiftDataIndexable {
    /// Default implementation uses the type name
    public static var debugDisplayName: String {
        return String(describing: self)
    }
    
    /// Default method to fetch all instances of this model type
    public static func fetchAllForDebug(from context: ModelContext) throws -> [any PersistentModel] {
        let descriptor = FetchDescriptor<Self>()
        return try context.fetch(descriptor).map { $0 as any PersistentModel }
    }
    
    /// Default implementation using reflection that filters out internal properties
    public func debugAttributes() -> [String: Any] {
        var attributes: [String: Any] = [:]
        
        let mirror = Mirror(reflecting: self)
        for case let (key?, value) in mirror.children {
            // Skip private/internal properties that start with _
            guard !key.hasPrefix("_") else { continue }
            
            // Handle different value types
            if let persistentModel = value as? (any PersistentModel) {
                // For relationships, show a summary instead of full object
                attributes[key] = "Related: \(type(of: persistentModel))"
            } else if let array = value as? [any PersistentModel] {
                // For relationship arrays, show count and type
                attributes[key] = "[\(array.count) items]"
            } else {
                attributes[key] = value
            }
        }
        
        return attributes
    }
}

// MARK: - ModelContext Extension for Automatic Discovery

extension ModelContext {
    /// Automatically discovers and fetches all SwiftDataIndexable models
    /// Uses the registry approach since schema introspection is limited in SwiftData
    @MainActor public func fetchAllIndexableData() throws -> [SwiftDataDebugEntity] {
        // Use the registry approach which is more reliable
        return try SwiftDataIndexableRegistry.fetchAllRegisteredData(from: self)
    }
    
    public func extractAttributes(from object: any PersistentModel) -> [String: Any] {
        // Use the protocol method if the object conforms to SwiftDataIndexable
        if let indexableObject = object as? (any SwiftDataIndexable) {
            return indexableObject.debugAttributes()
        }
        
        // Fallback for non-indexable objects (shouldn't happen in our registry system)
        var attributes: [String: Any] = [:]
        let mirror = Mirror(reflecting: object)
        for case let (key?, value) in mirror.children {
            guard !key.hasPrefix("_") else { continue }
            attributes[key] = value
        }
        return attributes
    }
}

// MARK: - Registry for Dynamic Discovery

/// Global registry of all SwiftDataIndexable types
/// This allows for completely automatic discovery without hardcoding types
@MainActor public struct SwiftDataIndexableRegistry {
    private static var registeredTypes: [any SwiftDataIndexable.Type] = []
    
    /// Register a SwiftDataIndexable type for automatic discovery
    public static func register<T: SwiftDataIndexable>(_ type: T.Type) {
        if !registeredTypes.contains(where: { $0 == type }) {
            registeredTypes.append(type)
        }
    }
    
    /// Get all registered indexable types
    public static var allRegisteredTypes: [any SwiftDataIndexable.Type] {
        return registeredTypes
    }
    
    /// Automatically discover and fetch all registered types
    public static func fetchAllRegisteredData(from context: ModelContext) throws -> [SwiftDataDebugEntity] {
        var debugEntities: [SwiftDataDebugEntity] = []
        
        for indexableType in allRegisteredTypes {
            let objects = try indexableType.fetchAllForDebug(from: context)
            let debugObjects = objects.map { object in
                SwiftDataDebugObject(
                    attributes: context.extractAttributes(from: object),
                    persistentModelID: object.persistentModelID
                )
            }
            
            debugEntities.append(SwiftDataDebugEntity(
                entityName: indexableType.debugDisplayName,
                objects: debugObjects
            ))
        }
        
        return debugEntities
    }
}
#endif
