//
//  DeleteCreditCardUseCase.swift
//  pagosApp
//
//  Use Case for deleting a credit card (metadata + Keychain secrets)
//  Clean Architecture - Domain Layer
//

import Foundation

@MainActor
final class DeleteCreditCardUseCase {
    private static let logCategory = "DeleteCreditCardUseCase"

    private let cardRepository: CreditCardRepositoryProtocol
    private let biometricRepository: BiometricRepositoryProtocol
    private let log: DomainLogWriter

    init(
        cardRepository: CreditCardRepositoryProtocol,
        biometricRepository: BiometricRepositoryProtocol,
        log: DomainLogWriter
    ) {
        self.cardRepository = cardRepository
        self.biometricRepository = biometricRepository
        self.log = log
    }

    /// Requires Face ID/Touch ID before deleting - a saved card's number and PIN
    /// shouldn't be erasable by a casual tap plus a confirmation alert alone.
    func execute(cardId: UUID, reason: String) async -> Result<Void, CardError> {
        let authResult = await biometricRepository.authenticateWithBiometric(reason: reason)
        guard case .success = authResult else {
            return .failure(.biometricFailed)
        }

        do {
            try await cardRepository.deleteCard(id: cardId)
            return .success(())
        } catch {
            log.error("Failed to delete card: \(error.localizedDescription)", category: Self.logCategory)
            return .failure(.deleteFailed(error.localizedDescription))
        }
    }
}
