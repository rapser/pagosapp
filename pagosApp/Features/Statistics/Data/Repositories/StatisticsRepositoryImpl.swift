//
//  StatisticsRepositoryImpl.swift
//  pagosApp
//
//  Statistics repository implementation
//  Clean Architecture: Wraps PaymentRepository and adds filtering logic
//

import Foundation

/// Repository implementation for Statistics feature
/// Wraps PaymentRepository and provides statistics-specific queries
@MainActor
final class StatisticsRepositoryImpl: StatisticsRepositoryProtocol {
    private static let logCategory = "StatisticsRepositoryImpl"

    private let paymentRepository: PaymentRepositoryProtocol
    private let log: DomainLogWriter
    private let calendar = Calendar.current

    // Short-lived cache: all calls within loadStatistics() (~100ms) share one DB read.
    private var paymentsCache: [Payment] = []
    private var cacheTimestamp: Date = .distantPast
    private let cacheLifetime: TimeInterval = 1.0

    init(paymentRepository: PaymentRepositoryProtocol, log: DomainLogWriter) {
        self.paymentRepository = paymentRepository
        self.log = log
    }

    private func fetchPaymentsCached() async throws -> [Payment] {
        if Date().timeIntervalSince(cacheTimestamp) < cacheLifetime {
            return paymentsCache
        }
        let payments = try await paymentRepository.getAllLocalPayments()
        paymentsCache = payments
        cacheTimestamp = Date()
        return payments
    }

    func getAllPayments() async -> Result<[Payment], PaymentError> {
        do {
            return .success(try await fetchPaymentsCached())
        } catch {
            log.error(L10n.Log.Payments.failedToGet(error.localizedDescription), category: Self.logCategory)
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func getFilteredPayments(
        filter: StatsFilter,
        currency: Currency
    ) async -> Result<[Payment], PaymentError> {
        let allPayments: [Payment]
        do {
            allPayments = try await fetchPaymentsCached()
        } catch {
            log.error(L10n.Log.Payments.failedToGet(error.localizedDescription), category: Self.logCategory)
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
        let allPayments: [Payment]
        do {
            allPayments = try await fetchPaymentsCached()
        } catch {
            log.error(L10n.Log.Payments.failedToGet(error.localizedDescription), category: Self.logCategory)
            return .failure(.unknown(error.localizedDescription))
        }

        let now = Date()

        // Calculate the start of the current month
        guard let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            log.error(L10n.Log.Statistics.failedStartMonth, category: Self.logCategory)
            return .success([])
        }

        // Calculate the end of the previous month
        guard let endOfPreviousMonth = calendar.date(byAdding: .day, value: -1, to: startOfCurrentMonth) else {
            log.error(L10n.Log.Statistics.failedEndPrevMonth, category: Self.logCategory)
            return .success([])
        }

        // Calculate the start of the period (N months before the end of the previous month)
        guard let startOfPeriod = calendar.date(byAdding: .month, value: -(count - 1), to: endOfPreviousMonth),
              let periodStart = calendar.date(from: calendar.dateComponents([.year, .month], from: startOfPeriod)) else {
            log.error(L10n.Log.Statistics.failedStartPeriod, category: Self.logCategory)
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
