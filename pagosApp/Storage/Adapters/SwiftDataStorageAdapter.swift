//
//  SwiftDataStorageAdapter.swift
//  pagosApp
//
//  Adapter for SwiftData local storage (Adapter Pattern)
//  Can be replaced with SQLiteStorageAdapter, RealmStorageAdapter, etc.
//

import Foundation
import SwiftData
import OSLog

/// Adapter to use SwiftData as LocalStorage implementation
/// This can be swapped with SQLite, Realm, CoreData implementations
/// Uses ModelContextExecutor for actor-isolated access to ModelContext
class SwiftDataStorageAdapter<Entity: PersistentModel>: LocalStorage {
    private let executor: ModelContextExecutor
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "SwiftDataStorage")
    
    @MainActor
    init(modelContext: ModelContext) {
        self.executor = ModelContextExecutor(modelContext: modelContext)
    }
    
    func fetchAll() async throws -> [Entity] {
        let descriptor = FetchDescriptor<Entity>()
        return try await executor.fetch(descriptor)
    }
    
    func fetch(where predicate: @Sendable (Entity) -> Bool) async throws -> [Entity] {
        // Modern Swift approach: fetch all and filter in memory with closure
        let allEntities = try await fetchAll()
        return allEntities.filter(predicate)
    }
    
    func save(_ entity: Entity) async throws {
        await executor.insert(entity)
        try await executor.save()
        logger.debug("✅ Entity saved to SwiftData")
    }
    
    func saveAll(_ entities: [Entity]) async throws {
        for entity in entities {
            await executor.insert(entity)
        }
        try await executor.save()
        logger.debug("✅ \(entities.count) entities saved to SwiftData")
    }
    
    func delete(_ entity: Entity) async throws {
        await executor.delete(entity)
        try await executor.save()
        logger.debug("✅ Entity deleted from SwiftData")
    }
    
    func deleteAll(_ entities: [Entity]) async throws {
        for entity in entities {
            await executor.delete(entity)
        }
        try await executor.save()
        logger.debug("✅ \(entities.count) entities deleted from SwiftData")
    }
    
    func clear() async throws {
        let allEntities = try await fetchAll()
        try await deleteAll(allEntities)
        logger.debug("✅ All entities cleared from SwiftData")
    }
    
    func exists(_ entity: Entity) async throws -> Bool {
        // SwiftData doesn't have a direct exists check
        // This is a simple implementation, can be optimized
        let all = try await fetchAll()
        return all.contains(where: { $0.persistentModelID == entity.persistentModelID })
    }
}
