//
//  RemoteStorage.swift
//  pagosApp
//
//  Protocol abstraction for remote storage (Strategy Pattern)
//  This allows switching between Supabase, Firebase, AWS, REST APIs, etc.
//

import Foundation

/// Generic protocol for remote data persistence
/// Allows swapping implementations (Supabase, Firebase, AWS, REST API)
protocol RemoteStorage {
    associatedtype DTO: Codable
    associatedtype Identifier: Hashable
    
    /// Fetch all entities for a user
    func fetchAll(userId: UUID) async throws -> [DTO]
    
    /// Fetch single entity by ID
    func fetchById(_ id: Identifier) async throws -> DTO?
    
    /// Insert or update a single entity
    func upsert(_ dto: DTO, userId: UUID) async throws
    
    /// Insert or update multiple entities
    func upsertAll(_ dtos: [DTO], userId: UUID) async throws
    
    /// Delete a single entity
    func delete(id: Identifier) async throws
    
    /// Delete multiple entities
    func deleteAll(ids: [Identifier]) async throws
}
