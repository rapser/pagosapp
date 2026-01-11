//
//  UserProfileLocalDTO.swift
//  pagosApp
//
//  SwiftData model for user profile local persistence
//  Clean Architecture: Data layer - Local DTO
//

import Foundation
import SwiftData

/// Local DTO for UserProfile persistence with SwiftData
/// Clean Architecture: DTOs handle serialization, Domain models are pure
/// SwiftData manages thread-safety internally through ModelContext.
/// All access must go through ModelContext on @MainActor.
@Model
final class UserProfileLocalDTO {
    @Attribute(.unique) var userId: UUID
    var fullName: String
    var email: String
    var phone: String?
    var dateOfBirth: Date?
    var genderRawValue: String?
    var country: String?
    var city: String?
    var preferredCurrencyRawValue: String

    init(
        userId: UUID,
        fullName: String,
        email: String,
        phone: String? = nil,
        dateOfBirth: Date? = nil,
        gender: UserProfile.Gender? = nil,
        country: String? = nil,
        city: String? = nil,
        preferredCurrency: Currency
    ) {
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

    // MARK: - Computed Properties

    var gender: UserProfile.Gender? {
        get { genderRawValue.flatMap(UserProfile.Gender.init) }
        set { genderRawValue = newValue?.rawValue }
    }

    var preferredCurrency: Currency {
        get { Currency(rawValue: preferredCurrencyRawValue) ?? .pen }
        set { preferredCurrencyRawValue = newValue.rawValue }
    }
}
