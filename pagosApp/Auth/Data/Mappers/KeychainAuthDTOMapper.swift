//
//  KeychainAuthDTOMapper.swift
//  pagosApp
//
//  Mapper between Keychain DTOs and Domain Entities
//  Clean Architecture - Data Layer
//

import Foundation

/// Named components extracted from keychain credentials (avoids large tuples).
struct KeychainSessionComponents {
    let accessToken: String
    let refreshToken: String
    let userId: UUID
}

/// Mapper for converting between Keychain DTOs and Domain entities
struct KeychainAuthDTOMapper {

    // MARK: - DTO to Session Components

    /// Extract session components from Keychain credentials
    /// - Parameter dto: KeychainCredentialsDTO
    /// - Returns: Tokens and user id for session assembly
    func toSessionComponents(_ dto: KeychainCredentialsDTO) -> KeychainSessionComponents {
        let userId = UUID(uuidString: dto.userId) ?? UUID()
        return KeychainSessionComponents(
            accessToken: dto.accessToken,
            refreshToken: dto.refreshToken,
            userId: userId
        )
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
