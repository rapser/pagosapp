//
//  HistoryRepositoryProtocol.swift
//  pagosApp
//
//  Repository protocol for payment history
//  Clean Architecture - Domain Layer
//

import Foundation

/// Protocol for accessing payment history data
protocol HistoryRepositoryProtocol: Sendable {
    /// Get payment history with optional filter
    @MainActor
    func getPaymentHistory(filter: PaymentHistoryFilter) async throws -> [Payment]
}
