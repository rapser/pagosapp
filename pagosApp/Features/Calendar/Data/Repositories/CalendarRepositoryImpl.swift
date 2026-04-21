//
//  CalendarRepositoryImpl.swift
//  pagosApp
//
//  Calendar repository implementation
//  Clean Architecture: Wraps PaymentRepository and adds date filtering
//

import Foundation

/// Repository implementation for Calendar feature
/// Wraps PaymentRepository and provides calendar-specific queries
final class CalendarRepositoryImpl: CalendarRepositoryProtocol {
    private static let logCategory = "CalendarRepositoryImpl"

    private let paymentRepository: PaymentRepositoryProtocol
    private let log: DomainLogWriter
    private let calendar = Calendar.current

    init(paymentRepository: PaymentRepositoryProtocol, log: DomainLogWriter) {
        self.paymentRepository = paymentRepository
        self.log = log
        log.info(L10n.Log.Calendar.initRepo, category: Self.logCategory)
    }

    // MARK: - Calendar Queries

    func getPayments(forDate date: Date) async -> Result<[Payment], PaymentError> {
        log.debug(L10n.Log.Calendar.gettingForDate, category: Self.logCategory)

        // Get all payments first
        do {
            let allPayments = try await paymentRepository.getAllLocalPayments()

            // Filter by date
            let filtered = allPayments.filter { payment in
                calendar.isDate(payment.dueDate, inSameDayAs: date)
            }

            log.info(L10n.Log.Calendar.filteredForDate(filtered.count, allPayments.count), category: Self.logCategory)
            return .success(filtered)
        } catch {
            log.error(L10n.Log.Payments.failedToGet(error.localizedDescription), category: Self.logCategory)
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func getPayments(forMonth month: Date) async -> Result<[Payment], PaymentError> {
        log.debug(L10n.Log.Calendar.gettingForMonth, category: Self.logCategory)

        // Get all payments first
        do {
            let allPayments = try await paymentRepository.getAllLocalPayments()

            // Filter by month
            let filtered = allPayments.filter { payment in
                calendar.isDate(payment.dueDate, equalTo: month, toGranularity: .month)
            }

            log.info(L10n.Log.Calendar.filteredForMonth(filtered.count, allPayments.count), category: Self.logCategory)
            return .success(filtered)
        } catch {
            log.error(L10n.Log.Payments.failedToGet(error.localizedDescription), category: Self.logCategory)
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func getAllPayments() async -> Result<[Payment], PaymentError> {
        log.debug(L10n.Log.Calendar.gettingAll, category: Self.logCategory)

        do {
            let payments = try await paymentRepository.getAllLocalPayments()
            return .success(payments)
        } catch {
            log.error(L10n.Log.Payments.failedToGet(error.localizedDescription), category: Self.logCategory)
            return .failure(.unknown(error.localizedDescription))
        }
    }
}
