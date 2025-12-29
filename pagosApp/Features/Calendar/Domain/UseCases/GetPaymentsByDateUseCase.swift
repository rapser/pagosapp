//
//  GetPaymentsByDateUseCase.swift
//  pagosApp
//
//  Use Case: Get payments for a specific date
//  Clean Architecture: Business logic in Domain layer
//

import Foundation
import OSLog

/// Get all payments due on a specific date
final class GetPaymentsByDateUseCase {
    private let calendarRepository: CalendarRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "GetPaymentsByDateUseCase")

    init(calendarRepository: CalendarRepositoryProtocol) {
        self.calendarRepository = calendarRepository
    }

    /// Execute: Get payments for a specific date
    /// - Parameter date: The date to filter payments
    /// - Returns: Result with array of PaymentEntity or PaymentError
    func execute(for date: Date) async -> Result<[PaymentEntity], PaymentError> {
        logger.debug("📅 Getting payments for date: \(date)")

        let result = await calendarRepository.getPayments(forDate: date)

        if case .success(let payments) = result {
            logger.info("✅ Found \(payments.count) payments for date")
        } else if case .failure(let error) = result {
            logger.error("❌ Failed to get payments: \(error.errorCode)")
        }

        return result
    }
}
