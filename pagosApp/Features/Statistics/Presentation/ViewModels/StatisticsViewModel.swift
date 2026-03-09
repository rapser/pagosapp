//
//  StatisticsViewModel.swift
//  pagosApp
//
//  ViewModel for Statistics using Clean Architecture
//  Uses Use Cases instead of direct SwiftData queries
//

import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class StatisticsViewModel {
    // MARK: - Observable Properties (UI State)

    var categoryStats: [CategoryStats] = []
    var monthlyStats: [MonthlyStats] = []
    var totalSpending: Double = 0
    var selectedFilter: StatsFilter = .all
    var selectedCurrency: Currency = .pen
    var errorMessage: String?
    var hasPENPayments: Bool = false
    var hasUSDPayments: Bool = false

    // MARK: - Dependencies (Use Cases)

    private let calculateCategoryStatsUseCase: CalculateCategoryStatsUseCase
    private let calculateMonthlyStatsUseCase: CalculateMonthlyStatsUseCase
    private let getTotalSpendingUseCase: GetTotalSpendingUseCase
    private let checkPaymentsByCurrencyUseCase: CheckPaymentsByCurrencyUseCase
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "StatisticsViewModel")

    init(
        calculateCategoryStatsUseCase: CalculateCategoryStatsUseCase,
        calculateMonthlyStatsUseCase: CalculateMonthlyStatsUseCase,
        getTotalSpendingUseCase: GetTotalSpendingUseCase,
        checkPaymentsByCurrencyUseCase: CheckPaymentsByCurrencyUseCase
    ) {
        self.calculateCategoryStatsUseCase = calculateCategoryStatsUseCase
        self.calculateMonthlyStatsUseCase = calculateMonthlyStatsUseCase
        self.getTotalSpendingUseCase = getTotalSpendingUseCase
        self.checkPaymentsByCurrencyUseCase = checkPaymentsByCurrencyUseCase
    }

    // MARK: - Data Operations

    /// Load all statistics (reads from local SwiftData - fast, no loading indicator needed)
    func loadStatistics() async {
        await loadCategoryStats()
        await loadMonthlyStats()
        await loadTotalSpending()
        await loadAvailableCurrencies()
    }

    /// Load available currencies
    func loadAvailableCurrencies() async {
        hasPENPayments = await checkPaymentsByCurrencyUseCase.execute(currency: .pen)
        hasUSDPayments = await checkPaymentsByCurrencyUseCase.execute(currency: .usd)
    }

    /// Load category statistics
    func loadCategoryStats() async {
        let result = await calculateCategoryStatsUseCase.execute(
            filter: selectedFilter,
            currency: selectedCurrency
        )

        switch result {
        case .success(let stats):
            categoryStats = stats

        case .failure(let error):
            logger.error("Failed to load category stats: \(error.errorCode)")
            errorMessage = L10n.Statistics.errorCategory
        }
    }

    /// Load monthly statistics (last 6 months)
    func loadMonthlyStats() async {
        let result = await calculateMonthlyStatsUseCase.execute(
            monthCount: 6,
            currency: selectedCurrency
        )

        switch result {
        case .success(let stats):
            monthlyStats = stats

        case .failure(let error):
            logger.error("Failed to load monthly stats: \(error.errorCode)")
            errorMessage = L10n.Statistics.errorMonthly
        }
    }

    /// Load total spending
    func loadTotalSpending() async {
        let result = await getTotalSpendingUseCase.execute(
            filter: selectedFilter,
            currency: selectedCurrency
        )

        switch result {
        case .success(let total):
            totalSpending = total

        case .failure(let error):
            logger.error("Failed to load total spending: \(error.errorCode)")
        }
    }

    /// Update filter and reload statistics
    func updateFilter(_ newFilter: StatsFilter) async {
        selectedFilter = newFilter
        await loadStatistics()
    }

    /// Update currency and reload statistics
    func updateCurrency(_ newCurrency: Currency) async {
        selectedCurrency = newCurrency
        // Clear stats before reload to avoid showing stale data (PEN) with new currency (USD) during load
        categoryStats = []
        monthlyStats = []
        totalSpending = 0
        await loadStatistics()
    }

    /// Refresh all data
    func refresh() async {
        await loadStatistics()
    }

    // MARK: - Computed Properties for Presentation

    /// Single source of truth: charts are safe to show only when we have data and a valid total (avoids Swift Charts crash)
    var hasValidChartData: Bool {
        !categoryStats.isEmpty && totalSpending > 0 && totalSpending.isFinite
    }

    /// Convert domain entities to presentation models for Charts
    var categorySpendingData: [CategorySpendingUI] {
        categoryStats.map { CategorySpendingUI(from: $0) }
    }

    /// Convert domain entities to presentation models for Charts
    var monthlySpendingData: [MonthlySpendingUI] {
        monthlyStats.map { MonthlySpendingUI(from: $0) }
    }
}
