//
//  CreateCreditCardUseCase.swift
//  pagosApp
//
//  Use Case for registering a new credit card
//  Clean Architecture - Domain Layer
//

import Foundation

@MainActor
final class CreateCreditCardUseCase {
    private static let logCategory = "CreateCreditCardUseCase"

    private let cardRepository: CreditCardRepositoryProtocol
    private let biometricRepository: BiometricRepositoryProtocol
    private let validator: CreditCardValidator
    private let log: DomainLogWriter

    init(
        cardRepository: CreditCardRepositoryProtocol,
        biometricRepository: BiometricRepositoryProtocol,
        validator: CreditCardValidator = CreditCardValidator(),
        log: DomainLogWriter
    ) {
        self.cardRepository = cardRepository
        self.biometricRepository = biometricRepository
        self.validator = validator
        self.log = log
    }

    /// Registers a card. Blocks registration when biometrics aren't available on this
    /// device, since a stored PIN/number could then never be revealed again.
    func execute(
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

            guard await biometricRepository.canUseBiometrics() else {
                return .failure(.biometricUnavailable)
            }

            let digits = cardNumber.filter(\.isNumber)
            let last4 = String(digits.suffix(4))
            let brand = CardBrand.detect(from: digits)

            let card = CreditCard(
                bank: bank,
                customBankName: bank == .other ? customBankName : nil,
                brand: brand,
                last4: last4,
                expirationMonth: expirationMonth,
                expirationYear: expirationYear
            )

            try await cardRepository.saveCard(card, cardNumber: digits, pin: pin)
            return .success(card)
        } catch let error as CardError {
            return .failure(error)
        } catch {
            log.error("Failed to create card: \(error.localizedDescription)", category: Self.logCategory)
            return .failure(.saveFailed(error.localizedDescription))
        }
    }
}
