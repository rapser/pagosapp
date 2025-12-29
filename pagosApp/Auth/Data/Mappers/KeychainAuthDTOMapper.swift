//
//  KeychainAuthDTOMapper.swift
//  pagosApp
//
//  Mapper between Keychain DTOs and Domain Entities
//  Clean Architecture - Data Layer
//

import Foundation

/// Mapper for converting between Keychain DTOs and Domain entities
struct KeychainAuthDTOMapper {

    // MARK: - DTO to Session Components

    /// Extract session components from Keychain credentials
    /// - Parameter dto: KeychainCredentialsDTO
    /// - Returns: Tuple with tokens and userId
    func toSessionComponents(_ dto: KeychainCredentialsDTO) -> (accessToken: String, refreshToken: String, userId: UUID) {
        let userId = UUID(uuidString: dto.userId) ?? UUID()
        return (dto.accessToken, dto.refreshToken, userId)
    }

    // MARK: - Domain to DTO

    /// Create KeychainCredentialsDTO from session
    /// - Parameter session: AuthSession domain entity
    /// - Returns: KeychainCredentialsDTO
    func toDTO(from session: AuthSession) -> KeychainCredentialsDTO {
        KeychainCredentialsDTO(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            userId: session.user.id.uuidString
        )
    }
}
