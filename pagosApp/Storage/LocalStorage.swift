//
//  LocalStorage.swift
//  pagosApp
//
//  Protocol abstraction for local storage (Strategy Pattern)
//  This allows switching between SwiftData, SQLite, Realm, CoreData, etc.
//

import Foundation

/// Generic protocol for local data persistence
/// Allows swapping storage implementations (SwiftData, SQLite, Realm, CoreData)
@MainActor
protocol LocalStorage {
    associatedtype Entity
    
    /// Fetch all entities
    func fetchAll() async throws -> [Entity]
    
    /// Fetch entities matching a predicate
    func fetch(where predicate: NSPredicate?) async throws -> [Entity]
    
    /// Save a single entity
    func save(_ entity: Entity) async throws
    
    /// Save multiple entities
    func saveAll(_ entities: [Entity]) async throws
    
    /// Delete a single entity
    func delete(_ entity: Entity) async throws
    
    /// Delete multiple entities
    func deleteAll(_ entities: [Entity]) async throws
    
    /// Delete all entities of this type
    func clear() async throws
    
    /// Check if entity exists
    func exists(_ entity: Entity) async throws -> Bool
}

/// Protocol for entities that can be stored locally
protocol LocalStorable {
    associatedtype Identifier: Hashable
    var id: Identifier { get }
}

/// Specific protocol for Payment local storage
@MainActor
protocol PaymentLocalStorage: LocalStorage where Entity == Payment {
    /// Fetch payments by user ID (business logic specific)
    func fetchByUser(_ userId: UUID) async throws -> [Payment]
    
    /// Fetch unpaid payments
    func fetchUnpaid() async throws -> [Payment]
    
    /// Fetch payments pending sync
    func fetchPendingSync() async throws -> [Payment]
}

/// Specific protocol for UserProfile local storage
@MainActor
protocol UserProfileLocalStorage: LocalStorage where Entity == UserProfile {
    /// Fetch profile by user ID
    func fetchByUserId(_ userId: UUID) async throws -> UserProfile?
}
