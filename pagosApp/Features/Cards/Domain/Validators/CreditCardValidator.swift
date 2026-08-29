//
//  CreditCardValidator.swift
//  pagosApp
//
//  Domain Validator for CreditCard registration input
//  Clean Architecture - Domain Layer
//

import Foundation

/// Validates card registration business rules. CVV is intentionally never validated
/// here (or anywhere else) - it must never be requested, stored, or displayed.
struct CreditCardValidator {

    /// Validate the raw card number (digits only, plausible PAN length).
    func validateCardNumber(_ cardNumber: String) throws {
        let digits = cardNumber.filter(\.isNumber)
        guard (12...19).contains(digits.count) else {
            throw CardError.invalidCardNumber
        }
    }

    /// Validate the PIN (digits only, 4-6 digits).
    func validatePin(_ pin: String) throws {
        let digits = pin.filter(\.isNumber)
        guard digits.count == pin.count, (4...6).contains(digits.count) else {
            throw CardError.invalidPin
        }
    }

    /// Validate expiration month/year.
    func validateExpiration(month: Int, year: Int) throws {
        guard (1...12).contains(month) else {
            throw CardError.invalidExpiration
        }
        guard year >= Calendar.current.component(.year, from: Date()) else {
            throw CardError.invalidExpiration
        }
    }

    /// Validate the bank selection ("Otro" requires a non-empty custom name).
    func validateBank(_ bank: Bank, customBankName: String?) throws {
        guard bank == .other else { return }
        guard let customBankName, !customBankName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CardError.invalidBank
        }
    }
}
