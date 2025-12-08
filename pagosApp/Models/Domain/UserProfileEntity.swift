//
//  UserProfileEntity.swift
//  pagosApp
//
//  Domain entity for UserProfile (Sendable, thread-safe)
//  Clean Architecture: Domain layer models are Sendable and independent of persistence
//

import Foundation

/// Sendable domain entity for UserProfile
/// This is the thread-safe version used in business logic
struct UserProfileEntity: Sendable {
    let userId: UUID
    let fullName: String
    let email: String
    let phone: String?
    let dateOfBirth: Date?
    let gender: Gender?
    let country: String?
    let city: String?
    let preferredCurrency: Currency
    
    enum Gender: String, Codable, Sendable, CaseIterable {
        case masculino = "Masculino"
        case femenino = "Femenino"
        case otro = "Otro"
        case prefierNoDecir = "Prefiero no decir"
        
        var displayName: String {
            self.rawValue
        }
    }
}

// MARK: - Mapper Extensions

extension UserProfileEntity {
    /// Convert from SwiftData model to domain entity
    init(from model: UserProfile) {
        self.userId = model.userId
        self.fullName = model.fullName
        self.email = model.email
        self.phone = model.phone
        self.dateOfBirth = model.dateOfBirth
        self.gender = model.gender.map { Gender(rawValue: $0.rawValue) ?? nil } ?? nil
        self.country = model.country
        self.city = model.city
        self.preferredCurrency = model.preferredCurrency
    }
    
    /// Convert from domain entity to SwiftData model
    func toModel() -> UserProfile {
        let genderValue = gender.map { UserProfile.Gender(rawValue: $0.rawValue) ?? .prefierNoDecir }
        return UserProfile(
            userId: userId,
            fullName: fullName,
            email: email,
            phone: phone,
            dateOfBirth: dateOfBirth,
            gender: genderValue,
            country: country,
            city: city,
            preferredCurrency: preferredCurrency
        )
    }
}
