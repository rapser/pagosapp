//
//  PasswordValidator.swift
//  pagosApp
//
//  Domain validator for passwords
//  Clean Architecture - Domain Layer
//

import Foundation

struct PasswordValidator {
    /// Minimum password length required
    static let minimumLength = 8

    /// Validates password strength
    /// - Parameter password: Password string to validate
    /// - Returns: true if password meets requirements
    static func isValid(_ password: String) -> Bool {
        guard password.count >= minimumLength else { return false }

        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasDigit = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSymbol = password.range(of: "[!@#$%^&*]", options: .regularExpression) != nil
        return hasUppercase && hasDigit && hasSymbol
    }

    /// Validates password and throws error if invalid
    /// - Parameter password: Password string to validate
    /// - Throws: AuthError.weakPassword if password doesn't meet requirements
    static func validate(_ password: String) throws {
        guard isValid(password) else {
            throw AuthError.weakPassword
        }
    }
}
