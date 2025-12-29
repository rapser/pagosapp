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
        logger.info("✅ CalendarRepositoryImpl initialized")
    }

    // MARK: - Calendar Queries

    func getPayments(forDate date: Date) async -> Result<[PaymentEntity], PaymentError> {
        logger.debug("📅 Getting payments for specific date")

        // Get all payments first
        do {
            let allPayments = try await paymentRepository.getAllLocalPayments()

            // Filter by date
            let filtered = allPayments.filter { payment in
                calendar.isDate(payment.dueDate, inSameDayAs: date)
            }

            logger.info("✅ Filtered \(filtered.count) payments for date from \(allPayments.count) total")
            return .success(filtered)
        } catch {
            logger.error("❌ Failed to get payments: \(error.localizedDescription)")
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func getPayments(forMonth month: Date) async -> Result<[PaymentEntity], PaymentError> {
        logger.debug("📅 Getting payments for specific month")

        // Get all payments first
        do {
            let allPayments = try await paymentRepository.getAllLocalPayments()

            // Filter by month
            let filtered = allPayments.filter { payment in
                calendar.isDate(payment.dueDate, equalTo: month, toGranularity: .month)
            }

            logger.info("✅ Filtered \(filtered.count) payments for month from \(allPayments.count) total")
            return .success(filtered)
        } catch {
            logger.error("❌ Failed to get payments: \(error.localizedDescription)")
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func getAllPayments() async -> Result<[PaymentEntity], PaymentError> {
        logger.debug("📅 Getting all payments for calendar")

        do {
            let payments = try await paymentRepository.getAllLocalPayments()
            return .success(payments)
        } catch {
            logger.error("❌ Failed to get payments: \(error.localizedDescription)")
            return .failure(.unknown(error.localizedDescription))
        }
    }
}
