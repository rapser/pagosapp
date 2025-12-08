//
//  SupabaseRepository.swift
//  pagosApp
//
//  Base protocol for Supabase repositories
//  Created on 7/12/25.
//

import Foundation
import Supabase

/// Base protocol for repositories that interact with Supabase
/// Implements Repository Pattern with remote and local operations
protocol SupabaseRepository {
    associatedtype RemoteDTO: Codable
    associatedtype LocalModel
    
    var supabaseClient: SupabaseClient { get }
    var tableName: String { get }
    
    // Remote operations
    func fetchFromRemote(userId: UUID) async throws -> [RemoteDTO]
    func upsertToRemote(_ dto: RemoteDTO) async throws
    func deleteFromRemote(id: UUID) async throws
    
    // Local operations
    func getFromLocal(id: UUID) async throws -> LocalModel?
    func saveToLocal(_ model: LocalModel) async throws
    func deleteFromLocal(_ model: LocalModel) async throws
}

/// Default implementations for common Supabase operations
extension SupabaseRepository {
    
    /// Generic fetch all with user filter
    func fetchAll(userId: UUID, from table: String) async throws -> [RemoteDTO] {
        try await supabaseClient
            .from(table)
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
    }
    
    /// Generic upsert
    func upsert<T: Encodable>(_ data: T, to table: String) async throws {
        try await supabaseClient
            .from(table)
            .upsert(data)
            .execute()
    }
    
    /// Generic delete
    func delete(id: UUID, from table: String) async throws {
        try await supabaseClient
            .from(table)
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
