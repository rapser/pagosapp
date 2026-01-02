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

    // MARK: - Initialization

    init(paymentDependencyContainer: PaymentDependencyContainer) {
        self.paymentDependencyContainer = paymentDependencyContainer
    }

    // MARK: - Repository

    func makeStatisticsRepository() -> StatisticsRepositoryProtocol {
        return StatisticsRepositoryImpl(
            paymentRepository: paymentDependencyContainer.makePaymentRepository()
        )
    }

    // MARK: - Use Cases

    func makeCalculateCategoryStatsUseCase() -> CalculateCategoryStatsUseCase {
        return CalculateCategoryStatsUseCase(
            statisticsRepository: makeStatisticsRepository()
        )
    }

    func makeCalculateMonthlyStatsUseCase() -> CalculateMonthlyStatsUseCase {
        return CalculateMonthlyStatsUseCase(
            statisticsRepository: makeStatisticsRepository()
        )
    }

    func makeGetTotalSpendingUseCase() -> GetTotalSpendingUseCase {
        return GetTotalSpendingUseCase(
            statisticsRepository: makeStatisticsRepository()
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
