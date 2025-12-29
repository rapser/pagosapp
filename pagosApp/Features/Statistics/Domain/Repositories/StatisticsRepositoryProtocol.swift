//
//  StatisticsRepositoryProtocol.swift
//  pagosApp
//
//  Domain repository protocol for Statistics feature
//  Clean Architecture: Wraps PaymentRepository for statistics calculations
//

import Foundation

/// Protocol defining statistics-specific queries and calculations
protocol StatisticsRepositoryProtocol {
    /// Get all payments (for calculations)
    func getAllPayments() async -> Result<[Payment], PaymentError>

    /// Get payments filtered by time period and currency
    func getFilteredPayments(
        filter: StatsFilter,
        currency: Currency
    ) async -> Result<[Payment], PaymentError>

    /// Get payments for last N months (for monthly stats)
    func getPaymentsForLastMonths(
        count: Int,
        currency: Currency
    ) async -> Result<[Payment], PaymentError>
}
