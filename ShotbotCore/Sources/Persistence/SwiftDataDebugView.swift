//
//  SwiftDataDebugView.swift
//  ShotbotCore
//
//  Created by Claude Code on 8/10/25.
//

#if DEBUG
import SwiftUI
import SwiftData

public struct SwiftDataDebugView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var debugEntities: [SwiftDataDebugEntity] = []
    @State private var errorMessage: String?
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            contentView
                .navigationTitle("SwiftData Debug")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        refreshButton
                    }
                }
        }
        .onAppear {
            loadDebugData()
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if let errorMessage = errorMessage {
            errorView(errorMessage)
        } else if debugEntities.isEmpty {
            emptyStateView
        } else {
            debugListView
        }
    }
    
    private func errorView(_ message: String) -> some View {
        Text("Error: \(message)")
            .foregroundColor(.red)
            .padding()
    }
    
    private var emptyStateView: some View {
        Text("No data found")
            .foregroundColor(.secondary)
    }
    
    private var debugListView: some View {
        List {
            ForEach(debugEntities) { entity in
                debugEntitySection(entity)
            }
        }
    }
    
    private func debugEntitySection(_ entity: SwiftDataDebugEntity) -> some View {
        Section(header: Text("\(entity.entityName) (\(entity.objects.count))")) {
            ForEach(entity.objects) { object in
                DebugObjectRowView(object: object)
            }
        }
    }
    
    private var refreshButton: some View {
        Button("Refresh") {
            loadDebugData()
        }
    }
    
    private func loadDebugData() {
        do {
            debugEntities = try modelContext.fetchSwiftDataDebugData()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            debugEntities = []
        }
    }
}

struct DebugObjectRowView: View {
    let object: SwiftDataDebugObject
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            attributesView
            persistentModelIDView
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
    }
    
    private var attributesView: some View {
        ForEach(sortedAttributeKeys, id: \.self) { key in
            attributeRow(for: key)
        }
    }
    
    private var sortedAttributeKeys: [String] {
        Array(object.attributes.keys.sorted())
    }
    
    private func attributeRow(for key: String) -> some View {
        HStack(alignment: .top) {
            keyText(key)
            Spacer()
            valueText(for: key)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func keyText(_ key: String) -> some View {
        Text(key)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
    }
    
    private func valueText(for key: String) -> some View {
        Text(String(describing: object.attributes[key] ?? "nil"))
            .font(.caption)
            .foregroundColor(.primary)
            .multilineTextAlignment(.trailing)
            .lineLimit(nil)
    }
    
    @ViewBuilder
    private var persistentModelIDView: some View {
        if let persistentModelID = object.persistentModelID {
            HStack(alignment: .top) {
                idKeyText
                Spacer()
                idValueText(persistentModelID)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var idKeyText: some View {
        Text("ID")
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.blue)
    }
    
    private func idValueText(_ id: PersistentIdentifier) -> some View {
        Text(formatPersistentIdentifier(id))
            .font(.caption2)
            .foregroundColor(.blue)
            .lineLimit(nil)
            .multilineTextAlignment(.trailing)
    }
    
    private func formatPersistentIdentifier(_ id: PersistentIdentifier) -> String {
        let fullDescription = String(describing: id)
        
        // Extract the Core Data URL if present
        if let urlRange = fullDescription.range(of: "<x-coredata://[^>]+>", options: .regularExpression) {
            let url = String(fullDescription[urlRange])
            // Extract just the entity and unique part
            if let entityMatch = url.range(of: "/([^/]+)/p\\d+", options: .regularExpression) {
                let entityPart = String(url[entityMatch])
                return "CoreData: \(entityPart)"
            }
            return "CoreData: \(url)"
        }
        
        // Fallback to a shortened version
        if fullDescription.count > 50 {
            return "\(fullDescription.prefix(25))...\(fullDescription.suffix(25))"
        }
        
        return fullDescription
    }
}

#Preview {
    SwiftDataDebugView()
        .modelContainer(for: SDAnalyticEvent.self, inMemory: true)
}
#endif
