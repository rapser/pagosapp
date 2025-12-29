//
//  MonthlyStatsEntity.swift
//  pagosApp
//
//  Domain entity for monthly statistics
//  Clean Architecture: Domain layer models are Sendable and independent
//

import Foundation

/// Sendable domain entity for monthly spending statistics
struct MonthlyStatsEntity: Sendable, Identifiable {
    let id: UUID
    let month: Date
    let totalAmount: Double
    let currency: Currency
    let paymentCount: Int

    init(
        id: UUID = UUID(),
        month: Date,
        totalAmount: Double,
        currency: Currency,
        paymentCount: Int
    ) {
        self.id = id
        self.month = month
        self.totalAmount = totalAmount
        self.currency = currency
        self.paymentCount = paymentCount
    }

    /// Get month name for display
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: month).capitalized
    }

    /// Get abbreviated month name
    var monthAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: month).capitalized
    }
}
