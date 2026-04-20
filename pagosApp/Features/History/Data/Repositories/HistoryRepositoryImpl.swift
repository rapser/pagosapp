//
//  HistoryRepositoryImpl.swift
//  pagosApp
//
//  Repository implementation for payment history
//  Clean Architecture - Data Layer
//

import Foundation

/// Implementation of HistoryRepositoryProtocol
/// Delegates to PaymentRepository but adds history-specific logic
final class HistoryRepositoryImpl: HistoryRepositoryProtocol {
    private static let logCategory = "HistoryRepositoryImpl"

    private let paymentRepository: PaymentRepositoryProtocol
    private let log: DomainLogWriter

    init(paymentRepository: PaymentRepositoryProtocol, log: DomainLogWriter) {
        self.paymentRepository = paymentRepository
        self.log = log
    }

    func getPaymentHistory(filter: PaymentHistoryFilter) async throws -> [Payment] {
        log.info("📚 Fetching payment history with filter: \(filter.logDescription)", category: Self.logCategory)

        // Get all payments from underlying repository
        let allPayments = try await paymentRepository.getAllLocalPayments()

        // Apply history-specific filtering
        let filtered = applyFilter(filter, to: allPayments)

        // Sort by most recent due date first (history-specific sorting)
        let sorted = filtered.sorted { $0.dueDate > $1.dueDate }

        log.info("✅ Retrieved \(sorted.count) payments for history", category: Self.logCategory)
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
