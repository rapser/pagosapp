//
//  UserProfileRemoteDTOMapper.swift
//  pagosApp
//
//  Mapper implementation for UserProfileDTO ↔ UserProfile Domain
//  Clean Architecture - Data Layer Remote Mapper Implementation
//

import Foundation

/// Mapper for converting between UserProfileDTO (Remote) and UserProfile (Domain)
struct UserProfileRemoteDTOMapper: UserProfileRemoteDTOMapping {
    func toDomain(_ dto: UserProfileDTO) -> UserProfile {
        UserProfile(
            userId: dto.userId,
            fullName: dto.fullName,
            email: dto.email,
            phone: dto.phone,
            dateOfBirth: dto.dateOfBirth,
            gender: dto.gender.flatMap(UserProfile.Gender.init),
            country: dto.country,
            city: dto.city,
            preferredCurrency: Currency(rawValue: dto.preferredCurrency) ?? .pen
        )
    }

    func toRemoteDTO(_ domain: UserProfile) -> UserProfileDTO {
        UserProfileDTO(
            userId: domain.userId,
            fullName: domain.fullName,
            email: domain.email,
            phone: domain.phone,
            dateOfBirth: domain.dateOfBirth,
            gender: domain.gender?.rawValue,
            country: domain.country,
            city: domain.city,
            preferredCurrency: domain.preferredCurrency.rawValue
        )
    }
}
