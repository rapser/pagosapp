//
//  UserProfileUIMapper.swift
//  pagosApp
//
//  Mapper implementation for UserProfile Domain ↔ UserProfileUI Presentation
//  Clean Architecture - Presentation Layer Mapper Implementation
//

import Foundation

/// Mapper for converting between UserProfile (Domain) and UserProfileUI (Presentation)
struct UserProfileUIMapper: UserProfileUIMapping {
    func toUI(_ domain: UserProfile) -> UserProfileUI {
        UserProfileUI(
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

    func toDomain(_ ui: UserProfileUI) -> UserProfile {
        UserProfile(
            userId: ui.userId,
            fullName: ui.fullName,
            email: ui.email,
            phone: ui.phone,
            dateOfBirth: ui.dateOfBirth,
            gender: ui.gender,
            country: ui.country,
            city: ui.city,
            preferredCurrency: ui.preferredCurrency
        )
    }
}
