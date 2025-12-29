//
//  CategoryStatsEntity.swift
//  pagosApp
//
//  Domain entity for category statistics
//  Clean Architecture: Domain layer models are Sendable and independent
//

import Foundation

/// Sendable domain entity for category spending statistics
struct CategoryStatsEntity: Sendable, Identifiable {
    let id: UUID
    let category: PaymentCategory
    let totalAmount: Double
    let currency: Currency
    let paymentCount: Int

    init(
        id: UUID = UUID(),
        category: PaymentCategory,
        totalAmount: Double,
        currency: Currency,
        paymentCount: Int
    ) {
        self.id = id
        self.category = category
        self.totalAmount = totalAmount
        self.currency = currency
        self.paymentCount = paymentCount
    }

    /// Calculate percentage of total
    func percentage(of total: Double) -> Double {
        guard total > 0 else { return 0 }
        return (totalAmount / total) * 100
    }
}
