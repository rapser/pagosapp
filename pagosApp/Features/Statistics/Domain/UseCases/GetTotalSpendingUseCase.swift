//
//  GetTotalSpendingUseCase.swift
//  pagosApp
//
//  Use Case: Get total spending for filter and currency
//  Clean Architecture: Business logic in Domain layer
//

import Foundation

/// Calculate total spending for filtered payments
@MainActor
final class GetTotalSpendingUseCase {
    private static let logCategory = "GetTotalSpendingUseCase"

    private let statisticsRepository: StatisticsRepositoryProtocol
    private let log: DomainLogWriter

    init(statisticsRepository: StatisticsRepositoryProtocol, log: DomainLogWriter) {
        self.statisticsRepository = statisticsRepository
        self.log = log
    }

    /// Execute: Calculate total spending
    /// - Parameters:
    ///   - filter: Time period filter
    ///   - currency: Currency filter
    /// - Returns: Result with total amount or PaymentError
    func execute(filter: StatsFilter, currency: Currency) async -> Result<Double, PaymentError> {
        log.debug(
            "📊 Calculating total spending for filter: \(filter.logDescription), currency: \(currency.rawValue)",
            category: Self.logCategory
        )

        let result = await statisticsRepository.getFilteredPayments(filter: filter, currency: currency)

        guard case .success(let payments) = result else {
            if case .failure(let error) = result {
                log.error("❌ Failed to get payments: \(error.errorCode)", category: Self.logCategory)
                return .failure(error)
            }
            return .success(0)
        }

        let total = payments.reduce(Decimal(0)) { $0 + $1.amount }
        let totalDouble = Double(truncating: NSDecimalNumber(decimal: total))
        log.info("✅ Total spending: \(total) from \(payments.count) payments", category: Self.logCategory)

        return .success(totalDouble)
    }
}
