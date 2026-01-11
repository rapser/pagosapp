//
//  UserProfileValidator.swift
//  pagosApp
//
//  Domain validation logic for UserProfile
//  Clean Architecture: Validators in Domain layer
//

import Foundation

/// Validates UserProfile domain entities
struct UserProfileValidator {

    /// Validate email format
    func validateEmail(_ email: String) throws {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        guard emailPredicate.evaluate(with: email) else {
            throw UserProfileError.invalidEmail
        }
    }

    /// Validate phone number format (optional field)
    func validatePhoneNumber(_ phone: String?) throws {
        guard let phone = phone, !phone.isEmpty else {
            return // Phone is optional
        }

        // Basic phone validation: digits, spaces, +, -, ()
        let phoneRegex = "^[0-9\\s\\+\\-\\(\\)]{6,20}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)

        guard phonePredicate.evaluate(with: phone) else {
            throw UserProfileError.invalidPhoneNumber
        }
    }

    /// Validate full name (must not be empty)
    func validateFullName(_ fullName: String) throws {
        guard !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw UserProfileError.unknown("Full name cannot be empty")
        }
    }

    /// Validate complete profile entity
    func validate(_ profile: UserProfile) throws {
        try validateEmail(profile.email)
        try validatePhoneNumber(profile.phone)
        try validateFullName(profile.fullName)
    }
}
