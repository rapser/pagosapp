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

    var categoryStats: [CategoryStatsEntity] = []
    var monthlyStats: [MonthlyStatsEntity] = []
    var totalSpending: Double = 0
    var selectedFilter: StatsFilter = .all
    var selectedCurrency: Currency = .pen
    var isLoading = false
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

    /// Load all statistics
    func loadStatistics() async {
        isLoading = true
        defer { isLoading = false }

        await loadCategoryStats()
        await loadMonthlyStats()
        await loadTotalSpending()
        await loadAvailableCurrencies()
    }

    /// Load available currencies
    func loadAvailableCurrencies() async {
        hasPENPayments = await checkPaymentsByCurrencyUseCase.execute(currency: .pen)
        hasUSDPayments = await checkPaymentsByCurrencyUseCase.execute(currency: .usd)
        logger.info("✅ Currency availability - PEN: \(self.hasPENPayments), USD: \(self.hasUSDPayments)")
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
            logger.info("✅ Loaded \(stats.count) category stats")

        case .failure(let error):
            logger.error("❌ Failed to load category stats: \(error.errorCode)")
            errorMessage = "Error al cargar estadísticas por categoría"
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
            logger.info("✅ Loaded \(stats.count) monthly stats")

        case .failure(let error):
            logger.error("❌ Failed to load monthly stats: \(error.errorCode)")
            errorMessage = "Error al cargar estadísticas mensuales"
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
            logger.info("✅ Total spending: \(total)")

        case .failure(let error):
            logger.error("❌ Failed to load total spending: \(error.errorCode)")
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
        await loadStatistics()
    }

    /// Refresh all data
    func refresh() async {
        await loadStatistics()
    }

    // MARK: - Computed Properties for Presentation

    /// Convert domain entities to presentation models for Charts
    var categorySpendingData: [CategorySpending] {
        categoryStats.map { CategorySpending(from: $0) }
    }

    /// Convert domain entities to presentation models for Charts
    var monthlySpendingData: [MonthlySpending] {
        monthlyStats.map { MonthlySpending(from: $0) }
    }
}
