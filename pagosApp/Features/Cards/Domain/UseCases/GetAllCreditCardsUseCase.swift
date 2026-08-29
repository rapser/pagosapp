//
//  GetAllCreditCardsUseCase.swift
//  pagosApp
//
//  Use Case for fetching all registered credit cards (metadata only)
//  Clean Architecture - Domain Layer
//

import Foundation

@MainActor
final class GetAllCreditCardsUseCase {
    private static let logCategory = "GetAllCreditCardsUseCase"

    private let cardRepository: CreditCardRepositoryProtocol
    private let log: DomainLogWriter

    init(cardRepository: CreditCardRepositoryProtocol, log: DomainLogWriter) {
        self.cardRepository = cardRepository
        self.log = log
    }

    func execute() async -> Result<[CreditCard], CardError> {
        do {
            let cards = try await cardRepository.getAllCards()
            return .success(cards)
        } catch {
            log.error("Failed to fetch cards: \(error.localizedDescription)", category: Self.logCategory)
            return .failure(.unknown(error.localizedDescription))
        }
    }
}
