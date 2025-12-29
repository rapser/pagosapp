//
//  CalculateMonthlyStatsUseCase.swift
//  pagosApp
//
//  Use Case: Calculate monthly spending statistics
//  Clean Architecture: Business logic in Domain layer
//

import Foundation
import OSLog

/// Calculate spending statistics grouped by month (last 6 months)
final class CalculateMonthlyStatsUseCase {
    private let statisticsRepository: StatisticsRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "CalculateMonthlyStatsUseCase")
    private let calendar = Calendar.current

    init(statisticsRepository: StatisticsRepositoryProtocol) {
        self.statisticsRepository = statisticsRepository
    }

    /// Execute: Calculate monthly statistics for last N months
    /// - Parameters:
    ///   - monthCount: Number of months to include (default: 6)
    ///   - currency: Currency filter
    /// - Returns: Result with array of MonthlyStatsEntity or PaymentError
    func execute(monthCount: Int = 6, currency: Currency) async -> Result<[MonthlyStatsEntity], PaymentError> {
        logger.debug("📊 Calculating monthly stats for last \(monthCount) months, currency: \(currency.rawValue)")

        // Get payments for last N months
        let result = await statisticsRepository.getPaymentsForLastMonths(count: monthCount, currency: currency)

        guard case .success(let payments) = result else {
            if case .failure(let error) = result {
                logger.error("❌ Failed to get payments: \(error.errorCode)")
            }
            return result.map { _ in [] }
        }

        // Group by month (start of month)
        let groupedByMonth = Dictionary(grouping: payments) { payment in
            calendar.date(from: calendar.dateComponents([.year, .month], from: payment.dueDate)) ?? payment.dueDate
        }

        // Get the end of the previous month
        let now = Date()
        guard let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let endOfPreviousMonth = calendar.date(byAdding: .day, value: -1, to: startOfCurrentMonth) else {
            logger.error("❌ Failed to calculate date range")
            return .success([])
        }

        // Create stats for each month (last 6 completed months)
        var monthlyStats: [MonthlyStatsEntity] = []
        for i in 0..<monthCount {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: endOfPreviousMonth),
                  let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)) else {
                continue
            }

            let monthPayments = groupedByMonth[startOfMonth] ?? []
            let total = monthPayments.reduce(0) { $0 + $1.amount }

            monthlyStats.append(MonthlyStatsEntity(
                month: startOfMonth,
                totalAmount: total,
                currency: currency,
                paymentCount: monthPayments.count
            ))
        }

        // Sort by month ascending
        let sorted = monthlyStats.sorted { $0.month < $1.month }

        logger.info("✅ Calculated stats for \(sorted.count) months from \(payments.count) payments")
        return .success(sorted)
    }
}
