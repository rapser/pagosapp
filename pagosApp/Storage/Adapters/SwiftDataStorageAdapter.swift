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

/// Actor-isolated wrapper for ModelContext
/// This ensures all ModelContext operations happen on MainActor without forcing the entire adapter class
@MainActor
final class ModelContextExecutor {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetch<Entity: PersistentModel>(_ descriptor: FetchDescriptor<Entity>) throws -> [Entity] {
        try modelContext.fetch(descriptor)
    }
    
    func insert<Entity: PersistentModel>(_ entity: Entity) {
        modelContext.insert(entity)
    }
    
    func delete<Entity: PersistentModel>(_ entity: Entity) {
        modelContext.delete(entity)
    }
    
    func save() throws {
        try modelContext.save()
    }
}

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

/// Specific SwiftData adapter for Payment
final class PaymentSwiftDataStorage: SwiftDataStorageAdapter<Payment>, PaymentLocalStorage {
    
    func fetchByUser(_ userId: UUID) async throws -> [Payment] {
        // Local storage doesn't have userId field in Payment model
        // Return all payments as local storage only contains current user's data
        return try await fetchAll()
    }
    
    func fetchUnpaid() async throws -> [Payment] {
        let allPayments = try await fetchAll()
        return allPayments.filter { !$0.isPaid }
    }
    
    func fetchPendingSync() async throws -> [Payment] {
        let allPayments = try await fetchAll()
        // Payments that need sync are those with status .local or .modified
        return allPayments.filter { $0.syncStatus == .local || $0.syncStatus == .modified }
    }
}

/// Specific SwiftData adapter for UserProfile
final class UserProfileSwiftDataStorage: SwiftDataStorageAdapter<UserProfile>, UserProfileLocalStorage {
    
    func fetchByUserId(_ userId: UUID) async throws -> UserProfile? {
        let allProfiles = try await fetchAll()
        return allProfiles.first(where: { $0.userId == userId })
    }
}
