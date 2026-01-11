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

    init(paymentDependencyContainer: PaymentDependencyContainer) {
        self.paymentDependencyContainer = paymentDependencyContainer
    }

    // MARK: - Repositories

    func makeHistoryRepository() -> HistoryRepositoryProtocol {
        HistoryRepositoryImpl(
            paymentRepository: paymentDependencyContainer.makePaymentRepository()
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
            mapper: PaymentUIMapper()
        )
    }
}
