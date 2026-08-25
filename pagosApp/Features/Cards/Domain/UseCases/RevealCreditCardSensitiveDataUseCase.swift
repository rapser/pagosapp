//
//  RevealCreditCardSensitiveDataUseCase.swift
//  pagosApp
//
//  Use Case for revealing a card's full number and PIN behind Face ID/Touch ID
//  Clean Architecture - Domain Layer
//

import Foundation

@MainActor
final class RevealCreditCardSensitiveDataUseCase {
    private static let logCategory = "RevealCreditCardSensitiveDataUseCase"

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

    /// Authenticates with Face ID/Touch ID, then reads the card's full number and PIN
    /// from Keychain. The Keychain entry is itself `.biometryCurrentSet`-protected, so
    /// this is defense-in-depth: an app-level gate plus an OS-level one, not a single check.
    func execute(cardId: UUID, reason: String) async -> Result<CreditCardSensitiveData, CardError> {
        let authResult = await biometricRepository.authenticateWithBiometric(reason: reason)

        guard case .success = authResult else {
            return .failure(.biometricFailed)
        }

        do {
            let data = try await cardRepository.revealSensitiveData(cardId: cardId, context: nil)
            return .success(data)
        } catch {
            log.error("Failed to reveal card data: \(error.localizedDescription)", category: Self.logCategory)
            return .failure(.biometricFailed)
        }
    }
}
