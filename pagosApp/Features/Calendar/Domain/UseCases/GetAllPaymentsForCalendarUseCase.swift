//
//  GetAllPaymentsForCalendarUseCase.swift
//  pagosApp
//
//  Use Case: Get all payments (for calendar payment indicators)
//  Clean Architecture: Business logic in Domain layer
//

import Foundation
import OSLog

/// Get all payments (used to show payment indicators in calendar)
final class GetAllPaymentsForCalendarUseCase {
    private let calendarRepository: CalendarRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "GetAllPaymentsForCalendarUseCase")

    init(calendarRepository: CalendarRepositoryProtocol) {
        self.calendarRepository = calendarRepository
    }

    /// Execute: Get all payments
    /// - Returns: Result with array of PaymentEntity or PaymentError
    func execute() async -> Result<[PaymentEntity], PaymentError> {
        logger.debug("📅 Getting all payments for calendar")

        let result = await calendarRepository.getAllPayments()

        if case .success(let payments) = result {
            logger.info("✅ Found \(payments.count) total payments")
        } else if case .failure(let error) = result {
            logger.error("❌ Failed to get payments: \(error.errorCode)")
        }

        return result
    }
}
