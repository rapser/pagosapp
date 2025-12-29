//
//  GetPaymentsByMonthUseCase.swift
//  pagosApp
//
//  Use Case: Get payments for a specific month
//  Clean Architecture: Business logic in Domain layer
//

import Foundation
import OSLog

/// Get all payments due in a specific month
final class GetPaymentsByMonthUseCase {
    private let calendarRepository: CalendarRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "GetPaymentsByMonthUseCase")

    init(calendarRepository: CalendarRepositoryProtocol) {
        self.calendarRepository = calendarRepository
    }

    /// Execute: Get payments for a specific month
    /// - Parameter month: A date representing the month to filter payments
    /// - Returns: Result with array of Payment or PaymentError
    func execute(for month: Date) async -> Result<[Payment], PaymentError> {
        logger.debug("📅 Getting payments for month: \(month)")

        let result = await calendarRepository.getPayments(forMonth: month)

        if case .success(let payments) = result {
            logger.info("✅ Found \(payments.count) payments for month")
        } else if case .failure(let error) = result {
            logger.error("❌ Failed to get payments: \(error.errorCode)")
        }

        return result
    }
}
