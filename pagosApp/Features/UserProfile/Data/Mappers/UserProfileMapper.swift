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

    // MARK: - SwiftData Model ↔ Domain Entity

    /// Convert from SwiftData model to domain entity
    static func toDomain(from model: UserProfile) -> UserProfileEntity {
        return UserProfileEntity(
            userId: model.userId,
            fullName: model.fullName,
            email: model.email,
            phone: model.phone,
            dateOfBirth: model.dateOfBirth,
            gender: model.gender.map { UserProfileEntity.Gender(rawValue: $0.rawValue) ?? nil } ?? nil,
            country: model.country,
            city: model.city,
            preferredCurrency: model.preferredCurrency
        )
    }

    /// Convert from domain entity to SwiftData model
    static func toModel(from entity: UserProfileEntity) -> UserProfile {
        let genderValue = entity.gender.map { UserProfile.Gender(rawValue: $0.rawValue) ?? .prefierNoDecir }
        return UserProfile(
            userId: entity.userId,
            fullName: entity.fullName,
            email: entity.email,
            phone: entity.phone,
            dateOfBirth: entity.dateOfBirth,
            gender: genderValue,
            country: entity.country,
            city: entity.city,
            preferredCurrency: entity.preferredCurrency
        )
    }

    // MARK: - Remote DTO ↔ Domain Entity

    /// Convert from remote DTO to domain entity
    static func toDomain(from dto: UserProfileDTO) -> UserProfileEntity {
        return UserProfileEntity(
            userId: dto.userId,
            fullName: dto.fullName,
            email: dto.email,
            phone: dto.phone,
            dateOfBirth: dto.dateOfBirth,
            gender: dto.gender.flatMap { UserProfileEntity.Gender(rawValue: $0) },
            country: dto.country,
            city: dto.city,
            preferredCurrency: Currency(rawValue: dto.preferredCurrency) ?? .pen
        )
    }

    /// Convert from domain entity to remote DTO
    static func toRemoteDTO(from entity: UserProfileEntity) -> UserProfileDTO {
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
    static func toUpdateDTO(from entity: UserProfileEntity) -> ProfileUpdateDTO {
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
