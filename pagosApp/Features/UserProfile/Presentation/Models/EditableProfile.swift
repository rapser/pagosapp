//
//  EditableProfile.swift
//  pagosApp
//
//  Presentation model for editable profile form
//  Clean Architecture: Presentation layer - UI state model
//

import Foundation

/// ViewModel for profile editing
/// Maintains the state of editable fields
struct EditableProfile {
    var fullName: String
    var phone: String
    var city: String
    var dateOfBirth: Date?
    var gender: UserProfile.Gender?
    var preferredCurrency: Currency

    /// Initialize from UserProfileUI
    init(from profile: UserProfileUI) {
        self.fullName = profile.fullName
        self.phone = profile.phone ?? ""
        self.city = profile.city ?? ""
        self.dateOfBirth = profile.dateOfBirth
        self.gender = profile.gender
        self.preferredCurrency = profile.preferredCurrency
    }

    /// Apply changes to UserProfileUI and create new instance
    func applyTo(_ profile: UserProfileUI) -> UserProfileUI {
        UserProfileUI(
            userId: profile.userId,
            fullName: fullName,
            email: profile.email,
            phone: phone.isEmpty ? nil : phone,
            dateOfBirth: dateOfBirth,
            gender: gender,
            country: profile.country,
            city: city.isEmpty ? nil : city,
            preferredCurrency: preferredCurrency
        )
    }
}
