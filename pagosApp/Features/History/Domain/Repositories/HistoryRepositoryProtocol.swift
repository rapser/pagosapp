//
//  HistoryRepositoryProtocol.swift
//  pagosApp
//
//  Repository protocol for payment history
//  Clean Architecture - Domain Layer
//

import Foundation

/// Protocol for accessing payment history data
protocol HistoryRepositoryProtocol {
    /// Get payment history with optional filter
    func getPaymentHistory(filter: PaymentHistoryFilter) async throws -> [Payment]
}
