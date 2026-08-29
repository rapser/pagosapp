//
//  CreditCard.swift
//  pagosApp
//
//  Domain Entity for Credit Card (non-sensitive metadata only)
//  Clean Architecture - Domain Layer
//
//  The full card number and PIN are NOT part of this entity - they live only in
//  Keychain (see CreditCardSensitiveData / RevealCreditCardSensitiveDataUseCase).
//

import Foundation

/// Non-sensitive credit card metadata, safe to persist in SwiftData.
struct CreditCard: Identifiable, Sendable, Equatable {
    let id: UUID
    var bank: Bank
    var customBankName: String?
    var brand: CardBrand
    var last4: String
    var expirationMonth: Int
    var expirationYear: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        bank: Bank,
        customBankName: String? = nil,
        brand: CardBrand,
        last4: String,
        expirationMonth: Int,
        expirationYear: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.bank = bank
        self.customBankName = customBankName
        self.brand = brand
        self.last4 = last4
        self.expirationMonth = expirationMonth
        self.expirationYear = expirationYear
        self.createdAt = createdAt
    }

    /// Bank name to display: custom free-text name when `.other`, otherwise the enum's raw value.
    var bankDisplayName: String {
        guard bank == .other else { return bank.rawValue }
        guard let customBankName, !customBankName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Bank.other.rawValue
        }
        return customBankName
    }

    var maskedNumber: String { "•••• \(last4)" }

    var expirationDisplay: String { String(format: "%02d/%02d", expirationMonth, expirationYear % 100) }
}
