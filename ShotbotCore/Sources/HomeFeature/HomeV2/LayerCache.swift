//
//  LayerCache.swift
//  Shotbot
//
//  Created by Richard Witherspoon on 10/27/26.
//

import Foundation

/// Remembers drawn layers, dropping the ones used least recently when it grows past its memory budget.
///
/// The cache is an actor, so any number of tasks can ask for layers at once. It also builds each layer only once: when
/// several tasks ask for the same layer, the first one builds it and the others wait for that result.
actor LayerCache {
    private struct Entry {
        let layer: CachedLayer
        var lastUsed: UInt64
    }

    private let budget: Int
    private var entries = [String: Entry]()
    private var inFlight = [String: Task<CachedLayer, any Error>]()
    private var totalCost = 0
    private var clock: UInt64 = 0

    // MARK: - Initializer

    /// Creates a cache.
    /// - Parameter budget: The most memory, in bytes, the cached layers may use.
    init(budget: Int) {
        self.budget = budget
    }

    // MARK: - Public Helpers

    /// The layer for a key, built with `build` if it isn't cached.
    ///
    /// The build runs off the cache, so building one layer doesn't hold up the others.
    /// - Parameters:
    ///   - key: What identifies the layer.
    ///   - build: Draws the layer.
    func layer(for key: String, build: @escaping @Sendable () async throws -> CachedLayer) async throws -> CachedLayer {
        if let layer = touch(key) {
            return layer
        }

        if let task = inFlight[key] {
            return try await task.value
        }

        let task = Task.detached(priority: .userInitiated) { try await build() }
        inFlight[key] = task
        defer { inFlight[key] = nil }

        let layer = try await task.value
        insert(layer, for: key)
        return layer
    }

    /// Forgets every layer, such as when the system is low on memory. Layers being built finish and are cached again.
    func removeAll() {
        entries = [:]
        totalCost = 0
    }

    // MARK: - Private Helpers

    private func touch(_ key: String) -> CachedLayer? {
        guard var entry = entries[key] else { return nil }

        clock += 1
        entry.lastUsed = clock
        entries[key] = entry
        return entry.layer
    }

    private func insert(_ layer: CachedLayer, for key: String) {
        clock += 1

        if let old = entries[key] {
            totalCost -= old.layer.cost
        }

        entries[key] = Entry(layer: layer, lastUsed: clock)
        totalCost += layer.cost

        // Drop the least recently used layers until the cache fits, but never the one just added.
        while totalCost > budget, entries.count > 1 {
            guard let oldest = entries.min(by: { $0.value.lastUsed < $1.value.lastUsed }), oldest.key != key else { break }

            totalCost -= oldest.value.layer.cost
            entries[oldest.key] = nil
        }
    }
}
