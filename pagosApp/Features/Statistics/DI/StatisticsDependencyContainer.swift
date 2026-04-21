//
//  StatisticsDependencyContainer.swift
//  pagosApp
//
//  Dependency Injection Container for Statistics module
//  Clean Architecture - DI Layer
//

import Foundation

/// Dependency Injection container for Statistics feature
@MainActor
final class StatisticsDependencyContainer {
    private let paymentDependencyContainer: PaymentDependencyContainer
    private let log: DomainLogWriter

    // MARK: - Initialization

    init(paymentDependencyContainer: PaymentDependencyContainer, log: DomainLogWriter) {
        self.paymentDependencyContainer = paymentDependencyContainer
        self.log = log
    }

    // MARK: - Repository

    func makeStatisticsRepository() -> StatisticsRepositoryProtocol {
        return StatisticsRepositoryImpl(
            paymentRepository: paymentDependencyContainer.makePaymentRepository(),
            log: log
        )
    }

    // MARK: - Use Cases

    func makeCalculateCategoryStatsUseCase() -> CalculateCategoryStatsUseCase {
        return CalculateCategoryStatsUseCase(
            statisticsRepository: makeStatisticsRepository(),
            log: log
        )
    }

    func makeCalculateMonthlyStatsUseCase() -> CalculateMonthlyStatsUseCase {
        return CalculateMonthlyStatsUseCase(
            statisticsRepository: makeStatisticsRepository(),
            log: log
        )
    }

    func makeGetTotalSpendingUseCase() -> GetTotalSpendingUseCase {
        return GetTotalSpendingUseCase(
            statisticsRepository: makeStatisticsRepository(),
            log: log
        )
    }

    func makeCheckPaymentsByCurrencyUseCase() -> CheckPaymentsByCurrencyUseCase {
        return CheckPaymentsByCurrencyUseCase(
            paymentRepository: paymentDependencyContainer.makePaymentRepository()
        )
    }

    // MARK: - ViewModels

    func makeStatisticsViewModel() -> StatisticsViewModel {
        return StatisticsViewModel(
            calculateCategoryStatsUseCase: makeCalculateCategoryStatsUseCase(),
            calculateMonthlyStatsUseCase: makeCalculateMonthlyStatsUseCase(),
            getTotalSpendingUseCase: makeGetTotalSpendingUseCase(),
            checkPaymentsByCurrencyUseCase: makeCheckPaymentsByCurrencyUseCase()
        )
    }
}
