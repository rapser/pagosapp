//
//  PaymentValidator.swift
//  pagosApp
//
//  Domain Validator for Payment entities
//  Clean Architecture - Domain Layer
//

import Foundation

/// Validates payment business rules
struct PaymentValidator {

    /// Validate payment amount
    /// - Parameter amount: The amount to validate
    /// - Throws: PaymentError.invalidAmount if amount is not valid
    func validateAmount(_ amount: Double) throws {
        guard amount > 0 else {
            throw PaymentError.invalidAmount
        }
    }

    /// Validate payment date
    /// - Parameter date: The due date to validate
    /// - Throws: PaymentError.invalidDate if date is not valid
    func validateDate(_ date: Date) throws {
        // Allow past dates (for historical payments)
        // No validation needed currently, but can add future constraints if needed
    }

    /// Validate complete payment entity
    /// - Parameter payment: The payment entity to validate
    /// - Throws: PaymentError if any validation fails
    func validate(_ payment: PaymentEntity) throws {
        try validateAmount(payment.amount)
        try validateDate(payment.dueDate)

        // Validate name is not empty
        guard !payment.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PaymentError.invalidAmount // Could add .invalidName error
        }
    }
}
