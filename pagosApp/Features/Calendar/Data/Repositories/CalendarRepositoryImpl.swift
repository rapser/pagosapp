//
//  CalendarRepositoryImpl.swift
//  pagosApp
//
//  Calendar repository implementation
//  Clean Architecture: Wraps PaymentRepository and adds date filtering
//

import Foundation
import OSLog

/// Repository implementation for Calendar feature
/// Wraps PaymentRepository and provides calendar-specific queries
final class CalendarRepositoryImpl: CalendarRepositoryProtocol {
    private let paymentRepository: PaymentRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "CalendarRepositoryImpl")
    private let calendar = Calendar.current

    init(paymentRepository: PaymentRepositoryProtocol) {
        self.paymentRepository = paymentRepository
        logger.info("\(L10n.Log.Calendar.initRepo)")
    }

    // MARK: - Calendar Queries

    func getPayments(forDate date: Date) async -> Result<[Payment], PaymentError> {
        logger.debug("\(L10n.Log.Calendar.gettingForDate)")

        // Get all payments first
        do {
            let allPayments = try await paymentRepository.getAllLocalPayments()

            // Filter by date
            let filtered = allPayments.filter { payment in
                calendar.isDate(payment.dueDate, inSameDayAs: date)
            }

            logger.info("\(L10n.Log.Calendar.filteredForDate(filtered.count, allPayments.count))")
            return .success(filtered)
        } catch {
            logger.error("\(L10n.Log.Payments.failedToGet(error.localizedDescription))")
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func getPayments(forMonth month: Date) async -> Result<[Payment], PaymentError> {
        logger.debug("\(L10n.Log.Calendar.gettingForMonth)")

        // Get all payments first
        do {
            let allPayments = try await paymentRepository.getAllLocalPayments()

            // Filter by month
            let filtered = allPayments.filter { payment in
                calendar.isDate(payment.dueDate, equalTo: month, toGranularity: .month)
            }

            logger.info("\(L10n.Log.Calendar.filteredForMonth(filtered.count, allPayments.count))")
            return .success(filtered)
        } catch {
            logger.error("\(L10n.Log.Payments.failedToGet(error.localizedDescription))")
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func getAllPayments() async -> Result<[Payment], PaymentError> {
        logger.debug("\(L10n.Log.Calendar.gettingAll)")

        do {
            let payments = try await paymentRepository.getAllLocalPayments()
            return .success(payments)
        } catch {
            logger.error("\(L10n.Log.Payments.failedToGet(error.localizedDescription))")
            return .failure(.unknown(error.localizedDescription))
        }
    }
}
