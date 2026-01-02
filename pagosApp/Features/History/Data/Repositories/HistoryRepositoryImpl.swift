//
//  HistoryRepositoryImpl.swift
//  pagosApp
//
//  Repository implementation for payment history
//  Clean Architecture - Data Layer
//

import Foundation
import OSLog

/// Implementation of HistoryRepositoryProtocol
/// Delegates to PaymentRepository but adds history-specific logic
final class HistoryRepositoryImpl: HistoryRepositoryProtocol {
    private let paymentRepository: PaymentRepositoryProtocol
    private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "HistoryRepository")

    init(paymentRepository: PaymentRepositoryProtocol) {
        self.paymentRepository = paymentRepository
    }

    func getPaymentHistory(filter: PaymentHistoryFilter) async throws -> [Payment] {
        logger.info("📚 Fetching payment history with filter: \(filter.rawValue)")

        // Get all payments from underlying repository
        let allPayments = try await paymentRepository.getAllLocalPayments()

        // Apply history-specific filtering
        let filtered = applyFilter(filter, to: allPayments)

        // Sort by most recent due date first (history-specific sorting)
        let sorted = filtered.sorted { $0.dueDate > $1.dueDate }

        logger.info("✅ Retrieved \(sorted.count) payments for history")
        return sorted
    }

    // MARK: - Private Helpers

    private func applyFilter(_ filter: PaymentHistoryFilter, to payments: [Payment]) -> [Payment] {
        let now = Date()

        switch filter {
        case .completed:
            return payments.filter { $0.isPaid }
        case .overdue:
            return payments.filter { !$0.isPaid && $0.dueDate < now }
        case .all:
            return payments.filter { $0.isPaid || $0.dueDate < now }
        }
    }
}
