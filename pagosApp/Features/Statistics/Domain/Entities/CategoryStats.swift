//
//  CategoryStats.swift
//  pagosApp
//
//  Domain entity for category statistics
//  Clean Architecture: Domain layer models are Sendable and independent
//

import Foundation

/// Sendable domain entity for category spending statistics
/// Clean Architecture: Domain models are pure, no UI dependencies
struct CategoryStats: Sendable {
    let id: UUID
    let category: PaymentCategory
    let totalAmount: Decimal
    let currency: Currency
    let paymentCount: Int

    init(
        id: UUID = UUID(),
        category: PaymentCategory,
        totalAmount: Decimal,
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
    func percentage(of total: Decimal) -> Double {
        guard total > 0 else { return 0 }
        return NSDecimalNumber(decimal: (totalAmount / total) * 100).doubleValue
    }
}
