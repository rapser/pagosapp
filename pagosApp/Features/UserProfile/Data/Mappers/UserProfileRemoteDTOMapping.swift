//
//  UserProfileRemoteDTOMapping.swift
//  pagosApp
//
//  Protocol for mapping between UserProfileDTO (Remote Data) and UserProfile (Domain)
//  Clean Architecture - Data Layer Remote Mapper Protocol
//

import Foundation

/// Protocol for mapping between UserProfileDTO (Remote) and UserProfile (Domain)
/// SOLID: Dependency Inversion Principle - depend on abstractions
protocol UserProfileRemoteDTOMapping: Sendable {
    /// Convert from Remote DTO to Domain
    func toDomain(_ dto: UserProfileDTO) -> UserProfile

    /// Convert from Domain to Remote DTO
    func toRemoteDTO(_ domain: UserProfile) -> UserProfileDTO
}
