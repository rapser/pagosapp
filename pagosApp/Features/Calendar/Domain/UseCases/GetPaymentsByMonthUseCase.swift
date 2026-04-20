//
//  GetPaymentsByMonthUseCase.swift
//  pagosApp
//
//  Use Case: Get payments for a specific month
//  Clean Architecture: Business logic in Domain layer
//

import Foundation

/// Get all payments due in a specific month
final class GetPaymentsByMonthUseCase {
    private static let logCategory = "GetPaymentsByMonthUseCase"

    private let calendarRepository: CalendarRepositoryProtocol
    private let log: DomainLogWriter

    init(calendarRepository: CalendarRepositoryProtocol, log: DomainLogWriter) {
        self.calendarRepository = calendarRepository
        self.log = log
    }

    /// Execute: Get payments for a specific month
    /// - Parameter month: A date representing the month to filter payments
    /// - Returns: Result with array of Payment or PaymentError
    func execute(for month: Date) async -> Result<[Payment], PaymentError> {
        log.debug("📅 Getting payments for month: \(String(describing: month))", category: Self.logCategory)

        let result = await calendarRepository.getPayments(forMonth: month)

        if case .success(let payments) = result {
            log.info("✅ Found \(payments.count) payments for month", category: Self.logCategory)
        } else if case .failure(let error) = result {
            log.error("❌ Failed to get payments: \(error.errorCode)", category: Self.logCategory)
        }

        return result
    }
}
