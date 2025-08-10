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
    public func fetchSwiftDataDebugData() throws -> [SwiftDataDebugEntity] {
        // Access the underlying SQLite database directly
        return try fetchDataFromSQLiteDatabase()
    }
    
    private func fetchDataFromSQLiteDatabase() throws -> [SwiftDataDebugEntity] {
        var debugEntities: [SwiftDataDebugEntity] = []
        
        // Get the database file path from SwiftData
        guard let databaseURL = getDatabaseURL() else {
            throw SwiftDataDebugError.databaseNotFound
        }
        
        var database: OpaquePointer?
        
        // Open the SQLite database
        guard sqlite3_open(databaseURL.path, &database) == SQLITE_OK else {
            throw SwiftDataDebugError.databaseOpenFailed
        }
        
        defer {
            sqlite3_close(database)
        }
        
        // Query for all tables in the database
        let tableNames = try getAllTableNames(database: database)
        
        for tableName in tableNames {
            // Skip SQLite system tables
            guard !tableName.hasPrefix("sqlite_") && !tableName.hasPrefix("Z_") else { continue }
            
            let objects = try getAllRowsFromTable(tableName, database: database)
            let debugObjects = objects.map { row in
                SwiftDataDebugObject(
                    attributes: row,
                    persistentModelID: nil // SQLite rows don't have PersistentIdentifier
                )
            }
            
            debugEntities.append(SwiftDataDebugEntity(
                entityName: tableName,
                objects: debugObjects
            ))
        }
        
        return debugEntities
    }
    
    private func getDatabaseURL() -> URL? {
        // SwiftData stores the database in the container's configuration
        // We need to find the actual database file
        let urls = container.configurations.compactMap { $0.url }
        return urls.first
    }
    
    private func getAllTableNames(database: OpaquePointer?) throws -> [String] {
        var tableNames: [String] = []
        
        let query = "SELECT name FROM sqlite_master WHERE type='table'"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK else {
            throw SwiftDataDebugError.queryPreparationFailed
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            if let tableName = sqlite3_column_text(statement, 0) {
                tableNames.append(String(cString: tableName))
            }
        }
        
        return tableNames
    }
    
    private func getAllRowsFromTable(_ tableName: String, database: OpaquePointer?) throws -> [[String: Any]] {
        var rows: [[String: Any]] = []
        
        let query = "SELECT * FROM \(tableName)"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK else {
            throw SwiftDataDebugError.queryPreparationFailed
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        let columnCount = sqlite3_column_count(statement)
        
        while sqlite3_step(statement) == SQLITE_ROW {
            var row: [String: Any] = [:]
            
            for columnIndex in 0..<columnCount {
                let columnName = String(cString: sqlite3_column_name(statement, columnIndex))
                let columnType = sqlite3_column_type(statement, columnIndex)
                
                let value: Any
                switch columnType {
                case SQLITE_INTEGER:
                    value = sqlite3_column_int64(statement, columnIndex)
                case SQLITE_FLOAT:
                    value = sqlite3_column_double(statement, columnIndex)
                case SQLITE_TEXT:
                    if let text = sqlite3_column_text(statement, columnIndex) {
                        value = String(cString: text)
                    } else {
                        value = ""
                    }
                case SQLITE_BLOB:
                    let dataLength = sqlite3_column_bytes(statement, columnIndex)
                    if let dataPointer = sqlite3_column_blob(statement, columnIndex) {
                        value = Data(bytes: dataPointer, count: Int(dataLength))
                    } else {
                        value = Data()
                    }
                case SQLITE_NULL:
                    value = NSNull()
                default:
                    value = "Unknown type"
                }
                
                row[columnName] = value
            }
            
            rows.append(row)
        }
        
        return rows
    }
}

enum SwiftDataDebugError: Error {
    case databaseNotFound
    case databaseOpenFailed
    case queryPreparationFailed
}
#endif
