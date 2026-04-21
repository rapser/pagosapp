//
//  GetAllPaymentsForCalendarUseCase.swift
//  pagosApp
//
//  Use Case: Get all payments (for calendar payment indicators)
//  Clean Architecture: Business logic in Domain layer
//

import Foundation

/// Get all payments (used to show payment indicators in calendar)
final class GetAllPaymentsForCalendarUseCase {
    private static let logCategory = "GetAllPaymentsForCalendarUseCase"

    private let calendarRepository: CalendarRepositoryProtocol
    private let log: DomainLogWriter

    init(calendarRepository: CalendarRepositoryProtocol, log: DomainLogWriter) {
        self.calendarRepository = calendarRepository
        self.log = log
    }

    /// Execute: Get all payments
    /// - Returns: Result with array of Payment or PaymentError
    func execute() async -> Result<[Payment], PaymentError> {
        log.debug("📅 Getting all payments for calendar", category: Self.logCategory)

        let result = await calendarRepository.getAllPayments()

        if case .success(let payments) = result {
            log.info("✅ Found \(payments.count) total payments", category: Self.logCategory)
        } else if case .failure(let error) = result {
            log.error("❌ Failed to get payments: \(error.errorCode)", category: Self.logCategory)
        }

        return result
    }
}
