//
//  UserProfileDomainMapping.swift
//  pagosApp
//
//  Protocol for mapping between UserProfileLocalDTO (Data) and UserProfile (Domain)
//  Clean Architecture - Data Layer Mapper Protocol
//

import Foundation

/// Protocol for mapping between UserProfileLocalDTO (Data) and UserProfile (Domain)
/// SOLID: Dependency Inversion Principle - depend on abstractions
protocol UserProfileDomainMapping: Sendable {
    /// Convert from Local DTO to Domain
    func toDomain(_ dto: UserProfileLocalDTO) -> UserProfile

    /// Convert from Domain to Local DTO
    func toLocalDTO(_ domain: UserProfile) -> UserProfileLocalDTO
}
