//
//  ModelContainer+Debug.swift
//  ShotbotCore
//
//  Created by Ricky Witherspoon on 8/9/25.
//

#if DEBUG
import SwiftData
import SwiftTools
import CoreData

extension ModelContainer {
    @MainActor
    public func fetchDebugData() throws -> [DebugEntity] {
        // Print database URL info
        print("🔍 ModelContainer configurations:")
        for (index, config) in configurations.enumerated() {
            print("🔍 Config \(index): \(config)")
            print("🔍 Database URL: \(config.url)")
            print("🔍 CloudKit: \(config.cloudKitDatabase)")
            print("🔍 InMemory: \(config.isStoredInMemoryOnly)")
        }
        
        // Simple approach: try to fetch using actual SwiftData model types from schema
        var debugEntities: [DebugEntity] = []
        
        // Get the backing class name from schema entities
        for entity in schema.entities {
            let entityName = entity.name
            print("🔍 Schema entity: \(entityName)")
            
            // Try to dynamically instantiate a fetch descriptor
            if entityName == "SDAnalyticEvent" {
                let descriptor = FetchDescriptor<SDAnalyticEvent>()
                let objects = try mainContext.fetch(descriptor)
                print("🔍 Fetched \(objects.count) SDAnalyticEvent objects")
                
                if !objects.isEmpty {
                    let debugObjects = objects.map { object in
                        DebugObject(
                            attributes: extractAttributes(from: object),
                            managedObject: nil
                        )
                    }
                    debugEntities.append(DebugEntity(
                        entityName: "SDAnalyticEvent",
                        objects: debugObjects
                    ))
                }
            }
            
            if entityName == "SDAppVersion" {
                let descriptor = FetchDescriptor<SDAppVersion>()
                let objects = try mainContext.fetch(descriptor)
                print("🔍 Fetched \(objects.count) SDAppVersion objects")
                
                if !objects.isEmpty {
                    let debugObjects = objects.map { object in
                        DebugObject(
                            attributes: extractAttributes(from: object),
                            managedObject: nil
                        )
                    }
                    debugEntities.append(DebugEntity(
                        entityName: "SDAppVersion",
                        objects: debugObjects
                    ))
                }
            }
        }
        
        print("🔍 Final result: \(debugEntities.count) entities")
        return debugEntities
    }
    
    private func extractAttributes(from object: Any) -> [String: Any] {
        var attributes: [String: Any] = [:]
        
        let mirror = Mirror(reflecting: object)
        for case let (key?, value) in mirror.children {
            // Skip private/internal properties that start with _
            guard !key.hasPrefix("_") else { continue }
            
            // Handle different value types dynamically
            if let persistentModel = value as? (any PersistentModel) {
                // For relationships, show a summary instead of full object
                attributes[key] = "Related: \(type(of: persistentModel))"
            } else if let array = value as? [any PersistentModel] {
                // For relationship arrays, show count and type
                attributes[key] = "[\(array.count) items]"
            } else {
                // For primitive values, use as-is
                attributes[key] = value
            }
        }
        
        return attributes
    }
}
#endif
