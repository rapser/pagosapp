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

/// Protocol for DTOs that can be transferred remotely
protocol RemoteTransferable: Codable {
    associatedtype Identifier: Hashable
    var id: Identifier { get }
    var userId: UUID { get }
}

/// Specific protocol for Payment remote storage
protocol PaymentRemoteStorage: RemoteStorage where DTO == PaymentDTO, Identifier == UUID {
    /// Fetch payments with filters (optional business logic)
    func fetchFiltered(userId: UUID, from: Date?, to: Date?) async throws -> [PaymentDTO]
}

/// Specific protocol for UserProfile remote storage
protocol UserProfileRemoteStorage: RemoteStorage where DTO == UserProfileDTO, Identifier == UUID {
    /// Fetch profile by user ID
    func fetchProfile(userId: UUID) async throws -> UserProfileDTO?
    
    /// Update profile
    func updateProfile(_ dto: UserProfileDTO) async throws
}

/// Error types for remote storage operations
enum RemoteStorageError: LocalizedError {
    case networkError(Error)
    case unauthorized
    case notFound
    case serverError(String)
    case invalidResponse
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        case .unauthorized:
            return "No autorizado. Por favor inicia sesión nuevamente."
        case .notFound:
            return "Recurso no encontrado"
        case .serverError(let message):
            return "Error del servidor: \(message)"
        case .invalidResponse:
            return "Respuesta inválida del servidor"
        case .timeout:
            return "Tiempo de espera agotado"
        }
    }
}
