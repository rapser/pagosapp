//
//  GetPaymentsByDateUseCase.swift
//  pagosApp
//
//  Use Case: Get payments for a specific date
//  Clean Architecture: Business logic in Domain layer
//

import Foundation

/// Get all payments due on a specific date
@MainActor
final class GetPaymentsByDateUseCase {
    private static let logCategory = "GetPaymentsByDateUseCase"

    private let calendarRepository: CalendarRepositoryProtocol
    private let log: DomainLogWriter

    init(calendarRepository: CalendarRepositoryProtocol, log: DomainLogWriter) {
        self.calendarRepository = calendarRepository
        self.log = log
    }

    /// Execute: Get payments for a specific date
    /// - Parameter date: The date to filter payments
    /// - Returns: Result with array of Payment or PaymentError
    func execute(for date: Date) async -> Result<[Payment], PaymentError> {
        log.debug("📅 Getting payments for date: \(String(describing: date))", category: Self.logCategory)

        let result = await calendarRepository.getPayments(forDate: date)

        if case .success(let payments) = result {
            log.info("✅ Found \(payments.count) payments for date", category: Self.logCategory)
        } else if case .failure(let error) = result {
            log.error("❌ Failed to get payments: \(error.errorCode)", category: Self.logCategory)
        }

        return result
    }
}
