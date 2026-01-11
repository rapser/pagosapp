//
//  UserProfileMapper.swift
//  pagosApp
//
//  Bidirectional mapper between DTOs and Domain entities
//  Clean Architecture: Mappers in Data layer
//

import Foundation

/// Maps between UserProfile DTOs and Domain Entities
struct UserProfileMapper {

    // MARK: - SwiftData DTO ↔ Domain Entity

    /// Convert from SwiftData DTO to domain entity
    static func toDomain(from dto: UserProfileLocalDTO) -> UserProfile {
        let gender = dto.genderRawValue.flatMap { UserProfile.Gender(rawValue: $0) }
        let currency = Currency(rawValue: dto.preferredCurrencyRawValue) ?? .pen

        return UserProfile(
            userId: dto.userId,
            fullName: dto.fullName,
            email: dto.email,
            phone: dto.phone,
            dateOfBirth: dto.dateOfBirth,
            gender: gender,
            country: dto.country,
            city: dto.city,
            preferredCurrency: currency
        )
    }

    /// Convert from domain entity to SwiftData DTO
    static func toLocalDTO(from entity: UserProfile) -> UserProfileLocalDTO {
        return UserProfileLocalDTO(
            userId: entity.userId,
            fullName: entity.fullName,
            email: entity.email,
            phone: entity.phone,
            dateOfBirth: entity.dateOfBirth,
            gender: entity.gender,
            country: entity.country,
            city: entity.city,
            preferredCurrency: entity.preferredCurrency
        )
    }

    // MARK: - Remote DTO ↔ Domain Entity

    /// Convert from remote DTO to domain entity
    static func toDomain(from dto: UserProfileDTO) -> UserProfile {
        return UserProfile(
            userId: dto.userId,
            fullName: dto.fullName,
            email: dto.email,
            phone: dto.phone,
            dateOfBirth: dto.dateOfBirth,
            gender: dto.gender.flatMap { UserProfile.Gender(rawValue: $0) },
            country: dto.country,
            city: dto.city,
            preferredCurrency: Currency(rawValue: dto.preferredCurrency) ?? .pen
        )
    }

    /// Convert from domain entity to remote DTO
    static func toRemoteDTO(from entity: UserProfile) -> UserProfileDTO {
        return UserProfileDTO(
            userId: entity.userId,
            fullName: entity.fullName,
            email: entity.email,
            phone: entity.phone,
            dateOfBirth: entity.dateOfBirth,
            gender: entity.gender?.rawValue,
            country: entity.country,
            city: entity.city,
            preferredCurrency: entity.preferredCurrency.rawValue
        )
    }

    // MARK: - Domain Entity → ProfileUpdateDTO

    /// Convert from domain entity to update DTO
    static func toUpdateDTO(from entity: UserProfile) -> ProfileUpdateDTO {
        return ProfileUpdateDTO(
            fullName: entity.fullName,
            email: entity.email,
            phone: entity.phone,
            dateOfBirth: entity.dateOfBirth?.ISO8601Format(),
            gender: entity.gender?.rawValue,
            country: entity.country,
            city: entity.city,
            preferredCurrency: entity.preferredCurrency.rawValue
        )
    }
}
