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
    private let log: DomainLogWriter

    init(cardRepository: CreditCardRepositoryProtocol, log: DomainLogWriter) {
        self.cardRepository = cardRepository
        self.log = log
    }

    func execute(cardId: UUID) async -> Result<Void, CardError> {
        do {
            try await cardRepository.deleteCard(id: cardId)
            return .success(())
        } catch {
            log.error("Failed to delete card: \(error.localizedDescription)", category: Self.logCategory)
            return .failure(.deleteFailed(error.localizedDescription))
        }
    }
}
