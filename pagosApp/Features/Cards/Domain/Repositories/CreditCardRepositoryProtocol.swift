//
//  CreditCardRepositoryProtocol.swift
//  pagosApp
//
//  Repository contract for Credit Card operations
//  Clean Architecture - Domain Layer
//
//  Composes non-sensitive metadata (SwiftData) with sensitive data (Keychain,
//  biometry-gated) behind a single facade.
//

import Foundation
import LocalAuthentication

@MainActor
protocol CreditCardRepositoryProtocol {
    func getAllCards() async throws -> [CreditCard]

    func saveCard(_ card: CreditCard, cardNumber: String, pin: String) async throws

    func deleteCard(id: UUID) async throws

    /// Reads the sensitive data (full number + PIN) from Keychain for the given card id.
    /// The Keychain entry itself is `.biometryCurrentSet`-protected, so this read will
    /// prompt Face ID/Touch ID unless `context` already carries a successful evaluation.
    func revealSensitiveData(cardId: UUID, context: LAContext?) async throws -> CreditCardSensitiveData
}
