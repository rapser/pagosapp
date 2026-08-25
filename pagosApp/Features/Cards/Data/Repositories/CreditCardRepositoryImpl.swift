//
//  CreditCardRepositoryImpl.swift
//  pagosApp
//
//  Composes SwiftData (metadata) and Keychain (sensitive data) into one facade
//  Clean Architecture - Data Layer
//

import Foundation
import LocalAuthentication

@MainActor
final class CreditCardRepositoryImpl: CreditCardRepositoryProtocol {
    private let localDataSource: CreditCardLocalDataSource
    private let sensitiveDataSource: CreditCardSensitiveDataSource
    private let log: DomainLogWriter

    init(
        localDataSource: CreditCardLocalDataSource,
        sensitiveDataSource: CreditCardSensitiveDataSource,
        log: DomainLogWriter
    ) {
        self.localDataSource = localDataSource
        self.sensitiveDataSource = sensitiveDataSource
        self.log = log
    }

    func getAllCards() async throws -> [CreditCard] {
        try await localDataSource.fetchAll()
    }

    /// Writes Keychain first: if that fails, no metadata row is created, avoiding a
    /// "ghost card" whose sensitive data could never be revealed.
    func saveCard(_ card: CreditCard, cardNumber: String, pin: String) async throws {
        guard sensitiveDataSource.save(cardId: card.id, cardNumber: cardNumber, pin: pin) else {
            throw CardError.saveFailed("Keychain write failed")
        }

        do {
            try await localDataSource.save(card)
        } catch {
            // Roll back the Keychain entry so we don't leave orphaned secrets.
            sensitiveDataSource.delete(cardId: card.id)
            throw error
        }
    }

    /// Deletes Keychain secrets first (best-effort), then the metadata row.
    func deleteCard(id: UUID) async throws {
        sensitiveDataSource.delete(cardId: id)
        try await localDataSource.delete(id: id)
    }

    func revealSensitiveData(cardId: UUID, context: LAContext?) async throws -> CreditCardSensitiveData {
        guard let (cardNumber, pin) = sensitiveDataSource.retrieve(cardId: cardId, context: context) else {
            throw CardError.notFound
        }
        return CreditCardSensitiveData(cardNumber: cardNumber, pin: pin)
    }
}
