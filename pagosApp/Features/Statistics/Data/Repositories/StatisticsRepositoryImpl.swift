//
//  StatisticsRepositoryImpl.swift
//  pagosApp
//
//  Statistics repository implementation
//  Clean Architecture: Wraps PaymentRepository and adds filtering logic
//

import Foundation
import OSLog

/// Repository implementation for Statistics feature
/// Wraps PaymentRepository and provides statistics-specific queries
final class StatisticsRepositoryImpl: StatisticsRepositoryProtocol {
    private let paymentRepository: PaymentRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "StatisticsRepositoryImpl")
    private let calendar = Calendar.current

    init(paymentRepository: PaymentRepositoryProtocol) {
        self.paymentRepository = paymentRepository
    }

    func getAllPayments() async -> Result<[Payment], PaymentError> {
        do {
            let payments = try await paymentRepository.getAllLocalPayments()
            return .success(payments)
        } catch {
            logger.error("\(L10n.Log.Payments.failedToGet(error.localizedDescription))")
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func getFilteredPayments(
        filter: StatsFilter,
        currency: Currency
    ) async -> Result<[Payment], PaymentError> {
        // Get all payments first
        let allPayments: [Payment]
        do {
            allPayments = try await paymentRepository.getAllLocalPayments()
        } catch {
            logger.error("\(L10n.Log.Payments.failedToGet(error.localizedDescription))")
            return .failure(.unknown(error.localizedDescription))
        }

        // Filter by time period
        let now = Date()
        let timeFiltered: [Payment]

        switch filter {
        case .month:
            timeFiltered = allPayments.filter { calendar.isDate($0.dueDate, equalTo: now, toGranularity: .month) }
        case .year:
            timeFiltered = allPayments.filter { calendar.isDate($0.dueDate, equalTo: now, toGranularity: .year) }
        case .all:
            timeFiltered = allPayments
        }

        let filtered = timeFiltered.filter { $0.currency == currency }
        return .success(filtered)
    }

    func getPaymentsForLastMonths(
        count: Int,
        currency: Currency
    ) async -> Result<[Payment], PaymentError> {
        // Get all payments first
        let allPayments: [Payment]
        do {
            allPayments = try await paymentRepository.getAllLocalPayments()
        } catch {
            logger.error("\(L10n.Log.Payments.failedToGet(error.localizedDescription))")
            return .failure(.unknown(error.localizedDescription))
        }

        let now = Date()

        // Calculate the start of the current month
        guard let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            logger.error("\(L10n.Log.Statistics.failedStartMonth)")
            return .success([])
        }

        // Calculate the end of the previous month
        guard let endOfPreviousMonth = calendar.date(byAdding: .day, value: -1, to: startOfCurrentMonth) else {
            logger.error("\(L10n.Log.Statistics.failedEndPrevMonth)")
            return .success([])
        }

        // Calculate the start of the period (N months before the end of the previous month)
        guard let startOfPeriod = calendar.date(byAdding: .month, value: -(count - 1), to: endOfPreviousMonth),
              let periodStart = calendar.date(from: calendar.dateComponents([.year, .month], from: startOfPeriod)) else {
            logger.error("\(L10n.Log.Statistics.failedStartPeriod)")
            return .success([])
        }

        // Filter payments within the period and by currency
        let filtered = allPayments.filter { payment in
            let paymentStartOfDay = calendar.startOfDay(for: payment.dueDate)
            let isInPeriod = paymentStartOfDay >= periodStart && paymentStartOfDay <= endOfPreviousMonth
            return isInPeriod && payment.currency == currency
        }

        return .success(filtered)
    }
}
