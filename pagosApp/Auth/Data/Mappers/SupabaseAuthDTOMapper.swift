//
//  SupabaseAuthDTOMapper.swift
//  pagosApp
//
//  Mapper between Supabase DTOs and Domain Entities
//  Clean Architecture - Data Layer
//

import Foundation
import Supabase

/// Mapper for converting between Supabase DTOs and Domain entities
struct SupabaseAuthDTOMapper {

    // MARK: - DTO to Domain

    /// Map SupabaseSessionDTO to AuthSession domain entity
    func toDomain(_ dto: SupabaseSessionDTO) -> AuthSession {
        let user = toDomain(dto.user)

        return AuthSession(
            accessToken: dto.accessToken,
            refreshToken: dto.refreshToken,
            expiresAt: Date(timeIntervalSince1970: TimeInterval(dto.expiresAt)),
            user: user
        )
    }

    /// Map SupabaseUserDTO to AuthUser domain entity
    func toDomain(_ dto: SupabaseUserDTO) -> AuthUser {
        // Convert userMetadata from [String: AnyJSON] to [String: String]
        let metadata: [String: String] = dto.userMetadata.compactMapValues { value in
            if case .string(let str) = value {
                return str
            }
            return "\(value)"
        }

        return AuthUser(
            id: dto.id,
            email: dto.email,
            emailConfirmed: dto.emailConfirmedAt != nil,
            createdAt: dto.createdAt,
            metadata: metadata.isEmpty ? nil : metadata
        )
    }

    // MARK: - Supabase SDK to DTO

    /// Map Supabase Session to SupabaseSessionDTO
    func toDTO(_ session: Session) -> SupabaseSessionDTO {
        SupabaseSessionDTO(from: session)
    }

    /// Map Supabase User to SupabaseUserDTO
    func toDTO(_ user: User) -> SupabaseUserDTO {
        SupabaseUserDTO(from: user)
    }

    // MARK: - Error Mapping

    /// Map Supabase errors to AuthError domain errors
    func mapError(_ error: Error) -> AuthError {
        let errorMessage = error.localizedDescription.lowercased()

        if errorMessage.contains("invalid login credentials") ||
           errorMessage.contains("invalid email or password") {
            return .invalidCredentials
        } else if errorMessage.contains("user already registered") ||
                  errorMessage.contains("email already exists") {
            return .emailAlreadyExists
        } else if errorMessage.contains("password") && errorMessage.contains("short") {
            return .weakPassword
        } else if errorMessage.contains("invalid email") {
            return .invalidEmail
        } else if errorMessage.contains("user not found") {
            return .userNotFound
        } else if errorMessage.contains("expired") || errorMessage.contains("token") {
            return .sessionExpired
        } else {
            return .networkError(error.localizedDescription)
        }
    }
}
