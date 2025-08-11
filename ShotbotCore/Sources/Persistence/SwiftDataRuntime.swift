//
//  SwiftDataRuntime.swift
//  ShotbotCore
//
//  Runtime SwiftData introspection based on Stack Overflow solution
//  https://stackoverflow.com/questions/79731020/how-can-i-retrieve-all-swiftdata-values-at-runtime/79731122#79731122
//

#if DEBUG
import Foundation
import SwiftData
import CoreData

public struct DebugEntity: Identifiable {
    public let id = UUID()
    public let entityName: String
    public let objects: [DebugObject]
}

public struct DebugObject: Identifiable {
    public let id = UUID()
    public let attributes: [String: Any]
}

extension Schema.Entity {
    var metatype: any PersistentModel.Type {
        let mirror = Mirror(reflecting: self)
        return mirror.descendant("_objectType") as! any PersistentModel.Type
    }
}

extension ModelContext {
    func allModels() throws -> [any PersistentModel] {
        try container.schema.entities.map(\.metatype).flatMap { (type: any PersistentModel.Type) in
            try fetchAll(type)
        }
    }
    
    // helper for opening existentials
    func fetchAll<T: PersistentModel>(_ type: T.Type) throws -> [any PersistentModel] {
        try self.fetch(FetchDescriptor<T>())
    }
    
    func fetchDebugArray() throws -> [(any PersistentModel.Type, [[String: Any]])] {
        try fetchDebugArray(container.schema.entities.map(\.metatype))
    }
    
    func fetchDebugArray(_ types: [any PersistentModel.Type]) throws -> [(any PersistentModel.Type, [[String: Any]])] {
        try types.map {
            ($0, try fetchDebugArray($0))
        }
    }
    
    func fetchDebugArray<T: PersistentModel>(_ type: T.Type) throws -> [[String: Any]] {
        let models = try self.fetch(FetchDescriptor<T>())
        return models.compactMap(modelToDict)
    }
    
    private func modelToDict<T: PersistentModel>(_ model: T) -> [String: Any] {
        let mirror = Mirror(reflecting: model)
        let lut = mirror.descendant("_$backingData", "_storage", "lut", "backing") as! [String: Int]
        let arr = mirror.descendant("_$backingData", "_storage", "arr") as! [Any?]
        var retVal = [String: Any]()
        for (key, index) in lut {
            if let value = arr[index] {
                retVal[key] = value
            }
        }
        return retVal
    }
}

extension ModelContainer {
    @MainActor
    public func fetchAllRuntimeData() throws -> [DebugEntity] {
        var debugEntities: [DebugEntity] = []
        
        // Use the new fetchDebugArray method from ModelContext
        let debugData = try mainContext.fetchDebugArray()
        
        for (modelType, objects) in debugData {
            let entityName = String(describing: modelType)
            
            print("🔍 Found entity: \(entityName) with \(objects.count) objects")
            
            guard !objects.isEmpty else { continue }
            
            let debugObjects = objects.map {
                DebugObject(attributes: $0)
            }
            
            debugEntities.append(DebugEntity(
                entityName: entityName,
                objects: debugObjects
            ))
        }
        
        return debugEntities
    }
}

#endif
