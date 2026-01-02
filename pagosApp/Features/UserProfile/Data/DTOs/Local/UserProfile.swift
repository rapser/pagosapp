//
//  UserProfile.swift
//  pagosApp
//
//  SwiftData model for user profile local persistence
//  Clean Architecture: Data layer - Local DTO
//

import Foundation
import SwiftData

/// SwiftData model for user profile persistence
/// SwiftData manages thread-safety internally through ModelContext.
/// All access must go through ModelContext on @MainActor.
/// For thread-safe operations, use UserProfileEntity instead.
@Model
final class UserProfile {
    @Attribute(.unique) var userId: UUID
    var fullName: String
    var email: String
    var phone: String?
    var dateOfBirth: Date?
    var genderRawValue: String?
    var country: String?
    var city: String?
    var preferredCurrencyRawValue: String

    init(userId: UUID, fullName: String, email: String, phone: String? = nil, dateOfBirth: Date? = nil, gender: Gender? = nil, country: String? = nil, city: String? = nil, preferredCurrency: Currency) {
        self.userId = userId
        self.fullName = fullName
        self.email = email
        self.phone = phone
        self.dateOfBirth = dateOfBirth
        self.genderRawValue = gender?.rawValue
        self.country = country
        self.city = city
        self.preferredCurrencyRawValue = preferredCurrency.rawValue
    }

    // Computed properties
    var gender: Gender? {
        get { genderRawValue.flatMap(Gender.init) }
        set { genderRawValue = newValue?.rawValue }
    }

    var preferredCurrency: Currency {
        get { Currency(rawValue: preferredCurrencyRawValue) ?? .pen }
        set { preferredCurrencyRawValue = newValue.rawValue }
    }

    enum Gender: String, CaseIterable {
        case masculino = "Masculino"
        case femenino = "Femenino"
        case otro = "Otro"
        case prefierNoDecir = "Prefiero no decir"

        var displayName: String { rawValue }
    }
}
