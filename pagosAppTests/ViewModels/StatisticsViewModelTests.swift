//
//  StatisticsViewModelTests.swift
//  pagosAppTests
//
//  Unit tests for StatisticsViewModel.
//

import Foundation
import Testing
@testable import pagosApp

@Suite("StatisticsViewModel")
@MainActor
struct StatisticsViewModelTests {
    let statisticsRepository = MockStatisticsRepository()
    let paymentRepository = MockPaymentRepository()
    let sut: StatisticsViewModel

    init() {
        let categoryUseCase = CalculateCategoryStatsUseCase(
            statisticsRepository: statisticsRepository,
            log: NullLog()
        )
        let monthlyUseCase = CalculateMonthlyStatsUseCase(
            statisticsRepository: statisticsRepository,
            log: NullLog()
        )
        let totalUseCase = GetTotalSpendingUseCase(
            statisticsRepository: statisticsRepository,
            log: NullLog()
        )
        let currencyUseCase = CheckPaymentsByCurrencyUseCase(paymentRepository: paymentRepository)
        sut = StatisticsViewModel(
            calculateCategoryStatsUseCase: categoryUseCase,
            calculateMonthlyStatsUseCase: monthlyUseCase,
            getTotalSpendingUseCase: totalUseCase,
            checkPaymentsByCurrencyUseCase: currencyUseCase
        )
    }

    @Test func loadStatistics_populatesTotalsAndAvailableCurrencies() async {
        let dueDate = Date()
        statisticsRepository.filteredPayments = [
            Payment.make(amount: 100, currency: .pen, dueDate: dueDate, category: .servicios),
            Payment.make(amount: 50, currency: .pen, dueDate: dueDate, category: .vivienda),
        ]
        statisticsRepository.monthlyPayments = [
            Payment.make(amount: 75, currency: .pen, dueDate: dueDate)
        ]
        paymentRepository.payments = [
            Payment.make(currency: .pen),
            Payment.make(currency: .usd)
        ]

        await sut.loadStatistics()

        #expect(sut.penTotalSpending == 150)
        #expect(sut.hasPENPayments == true)
        #expect(sut.hasUSDPayments == true)
        #expect(!sut.categoryStats.isEmpty)
        #expect(!sut.monthlyStats.isEmpty)
    }

    @Test func isolatedMonthlyFailure_doesNotResetOtherResults() async {
        let dueDate = Date()
        statisticsRepository.filteredPayments = [
            Payment.make(amount: 125, currency: .pen, dueDate: dueDate, category: .servicios)
        ]
        statisticsRepository.shouldFailMonthlyPayments = true
        paymentRepository.payments = [Payment.make(currency: .pen)]

        await sut.loadStatistics()

        #expect(sut.penTotalSpending == 125)
        #expect(!sut.categoryStats.isEmpty)
        #expect(sut.monthlyStats.isEmpty)
        #expect(sut.hasPENPayments == true)
    }
}
