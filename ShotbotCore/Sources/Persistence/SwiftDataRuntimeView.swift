//
//  SwiftDataRuntimeView.swift
//  ShotbotCore
//
//  Runtime SwiftData debug view using reflection
//

#if DEBUG
import SwiftUI
import SwiftData

public struct SwiftDataRuntimeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var debugEntities: [RuntimeDebugEntity] = []
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            contentView
                .navigationTitle("SwiftData Runtime Debug")
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
        if isLoading {
            ProgressView("Loading...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = errorMessage {
            errorView(errorMessage)
        } else if debugEntities.isEmpty {
            emptyStateView
        } else {
            debugListView
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text("Error")
                .font(.headline)
            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No SwiftData models found")
                .foregroundColor(.secondary)
        }
    }
    
    private var debugListView: some View {
        List {
            ForEach(debugEntities) { entity in
                debugEntitySection(entity)
            }
        }
    }
    
    private func debugEntitySection(_ entity: RuntimeDebugEntity) -> some View {
        Section {
            ForEach(entity.objects) { object in
                RuntimeDebugObjectRowView(object: object)
            }
        } header: {
            HStack {
                Text(entity.entityName)
                    .font(.headline)
                Spacer()
                Text("\(entity.objects.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }
        }
    }
    
    private var refreshButton: some View {
        Button(action: loadDebugData) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "arrow.clockwise")
            }
        }
        .disabled(isLoading)
    }
    
    private func loadDebugData() {
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                debugEntities = try modelContext.container.fetchAllRuntimeData()
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
                debugEntities = []
            }
            isLoading = false
        }
    }
}

private struct RuntimeDebugObjectRowView: View {
    let object: RuntimeDebugObject
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main content
            if isExpanded {
                expandedView
            } else {
                collapsedView
            }
            
            // ID display
            if let persistentModelID = object.persistentModelID {
                idView(persistentModelID)
            }
        }
        .padding(.vertical, 4)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
    }
    
    private var collapsedView: some View {
        HStack {
            Text(summaryText)
                .font(.caption)
                .lineLimit(2)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var expandedView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Properties")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 4)
            
            ForEach(sortedAttributeKeys, id: \.self) { key in
                attributeRow(for: key)
            }
        }
    }
    
    private var summaryText: String {
        let primaryKeys = ["name", "title", "id", "identifier", "rawVersion", "createdAt"]
        for key in primaryKeys {
            if let value = object.attributes[key] {
                return "\(key): \(String(describing: value))"
            }
        }
        return "Object with \(object.attributes.count) properties"
    }
    
    private var sortedAttributeKeys: [String] {
        Array(object.attributes.keys.sorted())
    }
    
    private func attributeRow(for key: String) -> some View {
        HStack(alignment: .top) {
            Text(key)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(minWidth: 80, alignment: .leading)
            
            Spacer()
            
            Text(formatValue(object.attributes[key]))
                .font(.caption2)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
                .lineLimit(nil)
                .textSelection(.enabled)
        }
        .padding(.vertical, 1)
    }
    
    private func idView(_ id: PersistentIdentifier) -> some View {
        HStack {
            Text("ID")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.blue)
            Spacer()
            Text(formatPersistentIdentifier(id))
                .font(.caption2)
                .foregroundColor(.blue)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
        .padding(.top, 4)
    }
    
    private func formatValue(_ value: Any?) -> String {
        guard let value = value else { return "nil" }
        
        if let date = value as? Date {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        if let bool = value as? Bool {
            return bool ? "✓" : "✗"
        }
        
        let description = String(describing: value)
        if description.count > 100 {
            return String(description.prefix(97)) + "..."
        }
        return description
    }
    
    private func formatPersistentIdentifier(_ id: PersistentIdentifier) -> String {
        let fullDescription = String(describing: id)
        
        // Extract just the meaningful part
        if let match = fullDescription.range(of: "/p\\d+", options: .regularExpression) {
            return String(fullDescription[match])
        }
        
        // Fallback to truncated version
        if fullDescription.count > 30 {
            return "..." + String(fullDescription.suffix(27))
        }
        
        return fullDescription
    }
}

#Preview {
    SwiftDataRuntimeView()
        .modelContainer(for: SDAnalyticEvent.self, inMemory: true)
}
#endif
