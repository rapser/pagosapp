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
@MainActor
class SwiftDataStorageAdapter<Entity: PersistentModel>: LocalStorage {
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "SwiftDataStorage")
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchAll() async throws -> [Entity] {
        let descriptor = FetchDescriptor<Entity>()
        return try modelContext.fetch(descriptor)
    }
    
    func fetch(where predicate: NSPredicate?) async throws -> [Entity] {
        // For SwiftData, we can't use NSPredicate directly
        // This method is kept for protocol compliance but returns all entities
        // Subclasses should use fetchAll() and filter in memory instead
        return try await fetchAll()
    }
    
    func save(_ entity: Entity) async throws {
        modelContext.insert(entity)
        try modelContext.save()
        logger.debug("✅ Entity saved to SwiftData")
    }
    
    func saveAll(_ entities: [Entity]) async throws {
        for entity in entities {
            modelContext.insert(entity)
        }
        try modelContext.save()
        logger.debug("✅ \(entities.count) entities saved to SwiftData")
    }
    
    func delete(_ entity: Entity) async throws {
        modelContext.delete(entity)
        try modelContext.save()
        logger.debug("✅ Entity deleted from SwiftData")
    }
    
    func deleteAll(_ entities: [Entity]) async throws {
        for entity in entities {
            modelContext.delete(entity)
        }
        try modelContext.save()
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
@MainActor
class PaymentSwiftDataStorage: SwiftDataStorageAdapter<Payment>, PaymentLocalStorage {
    
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
@MainActor
class UserProfileSwiftDataStorage: SwiftDataStorageAdapter<UserProfile>, UserProfileLocalStorage {
    
    func fetchByUserId(_ userId: UUID) async throws -> UserProfile? {
        let allProfiles = try await fetchAll()
        return allProfiles.first(where: { $0.userId == userId })
    }
}

// MARK: - Future implementations (examples)

/*
/// Example: SQLite adapter (future implementation)
@MainActor
class PaymentSQLiteStorage: PaymentLocalStorage {
    typealias Entity = Payment
    private let database: SQLiteDatabase
    
    init(database: SQLiteDatabase) {
        self.database = database
    }
    
    func fetchAll() async throws -> [Payment] {
        // SQLite specific implementation
        try await database.query("SELECT * FROM payments")
    }
    
    // ... other methods
}

/// Example: Realm adapter (future implementation)
@MainActor
class PaymentRealmStorage: PaymentLocalStorage {
    typealias Entity = Payment
    private let realm: Realm
    
    init(realm: Realm) {
        self.realm = realm
    }
    
    func fetchAll() async throws -> [Payment] {
        // Realm specific implementation
        Array(realm.objects(PaymentRealmObject.self).map { $0.toDomain() })
    }
    
    // ... other methods
}
*/
