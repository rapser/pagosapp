//
//  EmailValidator.swift
//  pagosApp
//
//  Domain validator for email addresses
//  Clean Architecture - Domain Layer
//

import Foundation

struct EmailValidator {
    /// Validates email format using regex pattern
    /// - Parameter email: Email string to validate
    /// - Returns: true if email format is valid
    static func isValid(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    /// Validates email and throws error if invalid
    /// - Parameter email: Email string to validate
    /// - Throws: AuthError.invalidEmail if format is invalid
    static func validate(_ email: String) throws {
        guard isValid(email) else {
            throw AuthError.invalidEmail
        }
    }
}
