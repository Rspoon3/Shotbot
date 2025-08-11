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
    @State private var debugEntities: [DebugEntity] = []
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Body
    
    public var body: some View {
        contentView
            .navigationTitle("SwiftData Runtime Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    refreshButton
                }
            }
            .task {
                await loadDebugData()
            }
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            ProgressView("Loading...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage {
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
    
    private func debugEntitySection(_ entity: DebugEntity) -> some View {
        DisclosureGroup {
            ForEach(entity.objects) { object in
                RuntimeDebugObjectRowView(object: object)
            }
        } label: {
            HStack {
                Text(entity.entityName)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(entity.objects.count.formatted())
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
        Button {
            Task { await loadDebugData() }
        } label: {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "arrow.clockwise")
            }
        }
        .disabled(isLoading)
    }
    
    // MARK: - Private Helpers
    
    private func loadDebugData() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        
        do {
            debugEntities = try modelContext.container.fetchAllRuntimeData()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            debugEntities = []
        }
    }
}

#Preview {
    SwiftDataRuntimeView()
        .modelContainer(for: SDAnalyticEvent.self, inMemory: true)
}
#endif
