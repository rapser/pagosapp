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
protocol LocalStorage {
    associatedtype Entity
    
    /// Fetch all entities
    func fetchAll() async throws -> [Entity]
    
    /// Fetch entities matching a Swift closure (modern approach)
    func fetch(where predicate: @Sendable (Entity) -> Bool) async throws -> [Entity]
    
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

