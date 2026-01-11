//
//  CalculateCategoryStatsUseCase.swift
//  pagosApp
//
//  Use Case: Calculate category spending statistics
//  Clean Architecture: Business logic in Domain layer
//

import Foundation
import OSLog

/// Calculate spending statistics grouped by category
final class CalculateCategoryStatsUseCase {
    private let statisticsRepository: StatisticsRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "CalculateCategoryStatsUseCase")

    init(statisticsRepository: StatisticsRepositoryProtocol) {
        self.statisticsRepository = statisticsRepository
    }

    /// Execute: Calculate category statistics for filtered payments
    /// - Parameters:
    ///   - filter: Time period filter
    ///   - currency: Currency filter
    /// - Returns: Result with array of CategoryStats or PaymentError
    func execute(filter: StatsFilter, currency: Currency) async -> Result<[CategoryStats], PaymentError> {
        logger.debug("📊 Calculating category stats for filter: \(filter.rawValue), currency: \(currency.rawValue)")

        // Get filtered payments
        let result = await statisticsRepository.getFilteredPayments(filter: filter, currency: currency)

        guard case .success(let payments) = result else {
            if case .failure(let error) = result {
                logger.error("❌ Failed to get payments: \(error.errorCode)")
            }
            return result.map { _ in [] }
        }

        // Group by category and calculate totals
        let groupedByCategory = Dictionary(grouping: payments, by: { $0.category })

        let categoryStats = groupedByCategory.map { (category, categoryPayments) in
            let total = categoryPayments.reduce(0) { $0 + $1.amount }
            return CategoryStats(
                category: category,
                totalAmount: total,
                currency: currency,
                paymentCount: categoryPayments.count
            )
        }
        // Sort by total amount descending
        .sorted { $0.totalAmount > $1.totalAmount }

        logger.info("✅ Calculated stats for \(categoryStats.count) categories from \(payments.count) payments")
        return .success(categoryStats)
    }
}
