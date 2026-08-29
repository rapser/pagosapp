//
//  CardDependencyContainer.swift
//  pagosApp
//
//  Dependency Injection Container for the Cards feature
//  Clean Architecture - DI Layer
//
//  Fully local feature (no remote sync) - metadata lives in SwiftData, sensitive
//  fields (full number + PIN) live only in Keychain.
//

import Foundation
import SwiftData

@MainActor
final class CardDependencyContainer {
    private let modelContext: ModelContext
    private let log: DomainLogWriter

    private lazy var localDataSource: CreditCardLocalDataSource = {
        CreditCardSwiftDataDataSource(modelContext: modelContext, log: log)
    }()

    private lazy var sensitiveDataSource: CreditCardSensitiveDataSource = {
        KeychainCreditCardDataSource(log: log)
    }()

    private lazy var sharedCardRepository: CreditCardRepositoryProtocol = CreditCardRepositoryImpl(
        localDataSource: localDataSource,
        sensitiveDataSource: sensitiveDataSource,
        log: log
    )

    // Cards owns its own BiometricRepository instance - avoids coupling this feature
    // container to AuthDependencyContainer for an otherwise-generic capability.
    private lazy var biometricRepository: BiometricRepositoryProtocol = BiometricRepositoryImpl(log: log)

    init(modelContext: ModelContext, log: DomainLogWriter) {
        self.modelContext = modelContext
        self.log = log
    }

    // MARK: - Repository

    func makeCardRepository() -> CreditCardRepositoryProtocol {
        sharedCardRepository
    }

    // MARK: - Use Cases

    func makeCreateCreditCardUseCase() -> CreateCreditCardUseCase {
        CreateCreditCardUseCase(
            cardRepository: makeCardRepository(),
            biometricRepository: biometricRepository,
            log: log
        )
    }

    func makeGetAllCreditCardsUseCase() -> GetAllCreditCardsUseCase {
        GetAllCreditCardsUseCase(cardRepository: makeCardRepository(), log: log)
    }

    func makeUpdateCreditCardUseCase() -> UpdateCreditCardUseCase {
        UpdateCreditCardUseCase(cardRepository: makeCardRepository(), log: log)
    }

    func makeDeleteCreditCardUseCase() -> DeleteCreditCardUseCase {
        DeleteCreditCardUseCase(
            cardRepository: makeCardRepository(),
            biometricRepository: biometricRepository,
            log: log
        )
    }

    func makeRevealCreditCardSensitiveDataUseCase() -> RevealCreditCardSensitiveDataUseCase {
        RevealCreditCardSensitiveDataUseCase(
            cardRepository: makeCardRepository(),
            biometricRepository: biometricRepository,
            log: log
        )
    }

    // MARK: - ViewModels

    func makeCardsListViewModel() -> CardsListViewModel {
        CardsListViewModel(
            getAllCardsUseCase: makeGetAllCreditCardsUseCase(),
            deleteCardUseCase: makeDeleteCreditCardUseCase(),
            revealSensitiveDataUseCase: makeRevealCreditCardSensitiveDataUseCase()
        )
    }

    func makeAddCardViewModel() -> AddCardViewModel {
        AddCardViewModel(
            createCardUseCase: makeCreateCreditCardUseCase(),
            updateCardUseCase: makeUpdateCreditCardUseCase()
        )
    }
}
