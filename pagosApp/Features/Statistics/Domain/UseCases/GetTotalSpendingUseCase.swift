//
//  GetTotalSpendingUseCase.swift
//  pagosApp
//
//  Use Case: Get total spending for filter and currency
//  Clean Architecture: Business logic in Domain layer
//

import Foundation
import OSLog

/// Calculate total spending for filtered payments
final class GetTotalSpendingUseCase {
    private let statisticsRepository: StatisticsRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "GetTotalSpendingUseCase")

    init(statisticsRepository: StatisticsRepositoryProtocol) {
        self.statisticsRepository = statisticsRepository
    }

    /// Execute: Calculate total spending
    /// - Parameters:
    ///   - filter: Time period filter
    ///   - currency: Currency filter
    /// - Returns: Result with total amount or PaymentError
    func execute(filter: StatsFilter, currency: Currency) async -> Result<Double, PaymentError> {
        logger.debug("📊 Calculating total spending for filter: \(filter.rawValue), currency: \(currency.rawValue)")

        let result = await statisticsRepository.getFilteredPayments(filter: filter, currency: currency)

        guard case .success(let payments) = result else {
            if case .failure(let error) = result {
                logger.error("❌ Failed to get payments: \(error.errorCode)")
                return .failure(error)
            }
            return .success(0)
        }

        let total = payments.reduce(0) { $0 + $1.amount }
        logger.info("✅ Total spending: \(total) from \(payments.count) payments")

        return .success(total)
    }
}
