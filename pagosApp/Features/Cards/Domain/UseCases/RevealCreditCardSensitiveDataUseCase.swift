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
    /// from Keychain. The Keychain entry is itself `.biometryCurrentSet`-protected, but we
    /// pass the already-authenticated `LAContext` into both reads so the OS reuses this
    /// authentication instead of prompting again per item (2 reads = 2 extra prompts otherwise).
    func execute(cardId: UUID, reason: String) async -> Result<CreditCardSensitiveData, CardError> {
        let authResult = await biometricRepository.authenticateWithBiometricContext(reason: reason)

        guard case .success(let context) = authResult else {
            return .failure(.biometricFailed)
        }

        do {
            let data = try await cardRepository.revealSensitiveData(cardId: cardId, context: context)
            return .success(data)
        } catch {
            log.error("Failed to reveal card data: \(error.localizedDescription)", category: Self.logCategory)
            return .failure(.biometricFailed)
        }
    }
}
