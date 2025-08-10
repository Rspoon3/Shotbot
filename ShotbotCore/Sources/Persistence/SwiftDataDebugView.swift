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
        .padding(.vertical, 2)
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
        HStack {
            keyText(key)
            Spacer()
            valueText(for: key)
        }
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
    }
    
    @ViewBuilder
    private var persistentModelIDView: some View {
        if let persistentModelID = object.persistentModelID {
            HStack {
                idKeyText
                Spacer()
                idValueText(persistentModelID)
            }
        }
    }
    
    private var idKeyText: some View {
        Text("ID")
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.blue)
    }
    
    private func idValueText(_ id: PersistentIdentifier) -> some View {
        Text(String(describing: id))
            .font(.caption2)
            .foregroundColor(.blue)
            .lineLimit(1)
            .truncationMode(.middle)
    }
}

#Preview {
    SwiftDataDebugView()
        .modelContainer(for: SDAnalyticEvent.self, inMemory: true)
}
#endif