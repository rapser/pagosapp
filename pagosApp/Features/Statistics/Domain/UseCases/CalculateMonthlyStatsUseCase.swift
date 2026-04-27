//
//  CalculateMonthlyStatsUseCase.swift
//  pagosApp
//
//  Use Case: Calculate monthly spending statistics
//  Clean Architecture: Business logic in Domain layer
//

import Foundation

/// Calculate spending statistics grouped by month (last 6 months)
@MainActor
final class CalculateMonthlyStatsUseCase {
    private static let logCategory = "CalculateMonthlyStatsUseCase"

    private let statisticsRepository: StatisticsRepositoryProtocol
    private let log: DomainLogWriter
    private let calendar = Calendar.current

    init(statisticsRepository: StatisticsRepositoryProtocol, log: DomainLogWriter) {
        self.statisticsRepository = statisticsRepository
        self.log = log
    }

    /// Execute: Calculate monthly statistics for last N months
    /// - Parameters:
    ///   - monthCount: Number of months to include (default: 6)
    ///   - currency: Currency filter
    /// - Returns: Result with array of MonthlyStats or PaymentError
    func execute(monthCount: Int = 6, currency: Currency) async -> Result<[MonthlyStats], PaymentError> {
        log.debug(
            "📊 Calculating monthly stats for last \(monthCount) months, currency: \(currency.rawValue)",
            category: Self.logCategory
        )

        // Get payments for last N months
        let result = await statisticsRepository.getPaymentsForLastMonths(count: monthCount, currency: currency)

        guard case .success(let payments) = result else {
            if case .failure(let error) = result {
                log.error("❌ Failed to get payments: \(error.errorCode)", category: Self.logCategory)
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
            log.error("❌ Failed to calculate date range", category: Self.logCategory)
            return .success([])
        }

        // Create stats for each month (last 6 completed months)
        var monthlyStats: [MonthlyStats] = []
        for i in 0..<monthCount {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: endOfPreviousMonth),
                  let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)) else {
                continue
            }

            let monthPayments = groupedByMonth[startOfMonth] ?? []
            let total = monthPayments.reduce(0) { $0 + $1.amount }

            monthlyStats.append(MonthlyStats(
                month: startOfMonth,
                totalAmount: total,
                currency: currency,
                paymentCount: monthPayments.count
            ))
        }

        // Sort by month ascending
        let sorted = monthlyStats.sorted { $0.month < $1.month }

        log.info(
            "✅ Calculated stats for \(sorted.count) months from \(payments.count) payments",
            category: Self.logCategory
        )
        return .success(sorted)
    }
}
