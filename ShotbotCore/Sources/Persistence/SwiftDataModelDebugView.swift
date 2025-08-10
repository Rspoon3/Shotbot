//
//  SwiftDataModelDebugView.swift
//  ShotbotCore
//
//  Created by Claude Code on 8/10/25.
//

#if DEBUG
import SwiftUI
import SwiftData
import SwiftTools

public struct SwiftDataModelDebugView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var debugEntities: [DebugEntity] = []
    @State private var errorMessage: String?
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            contentView
                .navigationTitle("SwiftData Models")
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
    
    private func debugEntitySection(_ entity: DebugEntity) -> some View {
        Section(header: Text("\(entity.entityName) (\(entity.objects.count))")) {
            ForEach(entity.objects) { object in
                ModelDebugObjectRowView(object: object)
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
            // Use the ModelContainer extension
            let container = modelContext.container
            debugEntities = try container.fetchDebugData()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            debugEntities = []
        }
    }
}

struct ModelDebugObjectRowView: View {
    let object: DebugObject
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            attributesView
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
}

#Preview {
    SwiftDataModelDebugView()
        .modelContainer(for: SDAnalyticEvent.self, inMemory: true)
}
#endif