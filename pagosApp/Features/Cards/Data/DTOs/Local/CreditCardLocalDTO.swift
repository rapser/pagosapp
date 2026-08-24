//
//  CreditCardLocalDTO.swift
//  pagosApp
//
//  SwiftData model for CreditCard metadata (non-sensitive fields only)
//  Clean Architecture - Data Layer (Local DTO)
//
//  Full card number and PIN are never stored here - see KeychainCreditCardDataSource.
//

import Foundation
import SwiftData

@Model
final class CreditCardLocalDTO {
    @Attribute(.unique) var id: UUID
    var bankRawValue: String
    var customBankName: String?
    var brandRawValue: String
    var last4: String
    var expirationMonth: Int
    var expirationYear: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        bank: Bank,
        customBankName: String?,
        brand: CardBrand,
        last4: String,
        expirationMonth: Int,
        expirationYear: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.bankRawValue = bank.rawValue
        self.customBankName = customBankName
        self.brandRawValue = brand.rawValue
        self.last4 = last4
        self.expirationMonth = expirationMonth
        self.expirationYear = expirationYear
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    var bank: Bank {
        get { Bank(rawValue: bankRawValue) ?? .other }
        set { bankRawValue = newValue.rawValue }
    }

    var brand: CardBrand {
        get { CardBrand(rawValue: brandRawValue) ?? .unknown }
        set { brandRawValue = newValue.rawValue }
    }
}
