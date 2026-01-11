//
//  UserProfileDomainMapper.swift
//  pagosApp
//
//  Mapper implementation for UserProfileLocalDTO ↔ UserProfile Domain
//  Clean Architecture - Data Layer Mapper Implementation
//

import Foundation

/// Mapper for converting between UserProfileLocalDTO (Data) and UserProfile (Domain)
struct UserProfileDomainMapper: UserProfileDomainMapping {
    func toDomain(_ dto: UserProfileLocalDTO) -> UserProfile {
        UserProfile(
            userId: dto.userId,
            fullName: dto.fullName,
            email: dto.email,
            phone: dto.phone,
            dateOfBirth: dto.dateOfBirth,
            gender: dto.gender,
            country: dto.country,
            city: dto.city,
            preferredCurrency: dto.preferredCurrency
        )
    }

    func toLocalDTO(_ domain: UserProfile) -> UserProfileLocalDTO {
        UserProfileLocalDTO(
            userId: domain.userId,
            fullName: domain.fullName,
            email: domain.email,
            phone: domain.phone,
            dateOfBirth: domain.dateOfBirth,
            gender: domain.gender,
            country: domain.country,
            city: domain.city,
            preferredCurrency: domain.preferredCurrency
        )
    }
}
