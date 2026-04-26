//
//  CalculateCategoryStatsUseCase.swift
//  pagosApp
//
//  Use Case: Calculate category spending statistics
//  Clean Architecture: Business logic in Domain layer
//

import Foundation

/// Calculate spending statistics grouped by category
@MainActor
final class CalculateCategoryStatsUseCase {
    private static let logCategory = "CalculateCategoryStatsUseCase"

    private let statisticsRepository: StatisticsRepositoryProtocol
    private let log: DomainLogWriter

    init(statisticsRepository: StatisticsRepositoryProtocol, log: DomainLogWriter) {
        self.statisticsRepository = statisticsRepository
        self.log = log
    }

    /// Execute: Calculate category statistics for filtered payments
    /// - Parameters:
    ///   - filter: Time period filter
    ///   - currency: Currency filter
    /// - Returns: Result with array of CategoryStats or PaymentError
    func execute(filter: StatsFilter, currency: Currency) async -> Result<[CategoryStats], PaymentError> {
        log.debug(
            "📊 Calculating category stats for filter: \(filter.logDescription), currency: \(currency.rawValue)",
            category: Self.logCategory
        )

        // Get filtered payments
        let result = await statisticsRepository.getFilteredPayments(filter: filter, currency: currency)

        guard case .success(let payments) = result else {
            if case .failure(let error) = result {
                log.error("❌ Failed to get payments: \(error.errorCode)", category: Self.logCategory)
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

        log.info(
            "✅ Calculated stats for \(categoryStats.count) categories from \(payments.count) payments",
            category: Self.logCategory
        )
        return .success(categoryStats)
    }
}
