//
//  SwiftDataRegistry.swift
//  ShotbotCore
//
//  Created by Claude Code on 8/10/25.
//

#if DEBUG
import Foundation

/// Initializes the SwiftData debug registry with all indexable models
public struct SwiftDataRegistry {
    /// Call this once during app startup to register all models for debugging
    @MainActor public static func registerAllModels() {
        // Register all SwiftDataIndexable models here
        SwiftDataIndexableRegistry.register(SDAnalyticEvent.self)
        SwiftDataIndexableRegistry.register(SDAppVersion.self)
        
        // Add new models here as they're created:
        // SwiftDataIndexableRegistry.register(MyNewModel.self)
        
        print("🔍 SwiftData Debug: Registered \(SwiftDataIndexableRegistry.allRegisteredTypes.count) indexable model types")
    }
}
#endif
