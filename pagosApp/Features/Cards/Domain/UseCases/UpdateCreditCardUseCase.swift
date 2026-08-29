//
//  UpdateCreditCardUseCase.swift
//  pagosApp
//
//  Use Case for editing an existing credit card's metadata and Keychain secrets
//  Clean Architecture - Domain Layer
//

import Foundation

@MainActor
final class UpdateCreditCardUseCase {
    private static let logCategory = "UpdateCreditCardUseCase"

    private let cardRepository: CreditCardRepositoryProtocol
    private let validator: CreditCardValidator
    private let log: DomainLogWriter

    init(
        cardRepository: CreditCardRepositoryProtocol,
        validator: CreditCardValidator = CreditCardValidator(),
        log: DomainLogWriter
    ) {
        self.cardRepository = cardRepository
        self.validator = validator
        self.log = log
    }

    /// Updates a card in place, preserving its `id` and `createdAt`. Reaching this use
    /// case already required a successful biometric reveal of the current secrets, so
    /// no additional biometric gate is applied here.
    func execute(
        cardId: UUID,
        createdAt: Date,
        bank: Bank,
        customBankName: String?,
        cardNumber: String,
        pin: String,
        expirationMonth: Int,
        expirationYear: Int
    ) async -> Result<CreditCard, CardError> {
        do {
            try validator.validateBank(bank, customBankName: customBankName)
            try validator.validateCardNumber(cardNumber)
            try validator.validatePin(pin)
            try validator.validateExpiration(month: expirationMonth, year: expirationYear)

            let digits = cardNumber.filter(\.isNumber)
            let last4 = String(digits.suffix(4))
            let brand = CardBrand.detect(from: digits)

            let card = CreditCard(
                id: cardId,
                bank: bank,
                customBankName: bank == .other ? customBankName : nil,
                brand: brand,
                last4: last4,
                expirationMonth: expirationMonth,
                expirationYear: expirationYear,
                createdAt: createdAt
            )

            try await cardRepository.saveCard(card, cardNumber: digits, pin: pin)
            return .success(card)
        } catch let error as CardError {
            return .failure(error)
        } catch {
            log.error("Failed to update card: \(error.localizedDescription)", category: Self.logCategory)
            return .failure(.saveFailed(error.localizedDescription))
        }
    }
}
