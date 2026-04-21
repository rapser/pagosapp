//
//  HistoryDependencyContainer.swift
//  pagosApp
//
//  Dependency Injection Container for History module
//  Clean Architecture - DI Layer
//

import Foundation

/// Dependency injection container for History module
@MainActor
final class HistoryDependencyContainer {
    // MARK: - External Dependencies

    private let paymentDependencyContainer: PaymentDependencyContainer
    private let log: DomainLogWriter

    init(paymentDependencyContainer: PaymentDependencyContainer, log: DomainLogWriter) {
        self.paymentDependencyContainer = paymentDependencyContainer
        self.log = log
    }

    // MARK: - Repositories

    func makeHistoryRepository() -> HistoryRepositoryProtocol {
        HistoryRepositoryImpl(
            paymentRepository: paymentDependencyContainer.makePaymentRepository(),
            log: log
        )
    }

    // MARK: - Use Cases

    func makeGetPaymentHistoryUseCase() -> GetPaymentHistoryUseCase {
        GetPaymentHistoryUseCase(
            historyRepository: makeHistoryRepository()
        )
    }

    // MARK: - ViewModels

    func makePaymentHistoryViewModel() -> PaymentHistoryViewModel {
        PaymentHistoryViewModel(
            getPaymentHistoryUseCase: makeGetPaymentHistoryUseCase(),
            eventBus: paymentDependencyContainer.eventBus,
            mapper: PaymentUIMapper()
        )
    }
}
