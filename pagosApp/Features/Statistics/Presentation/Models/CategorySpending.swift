//
//  CategorySpending.swift
//  pagosApp
//
//  Presentation model for category spending (for Charts)
//  Clean Architecture: Presentation layer - UI state model
//

import Foundation

/// Presentation model for category spending statistics (used in Charts)
struct CategorySpending: Identifiable {
    let id = UUID()
    let category: PaymentCategory
    let totalAmount: Double
    let currency: Currency

    /// Initialize from domain entity
    init(from entity: CategoryStats) {
        self.category = entity.category
        self.totalAmount = Double(truncating: NSDecimalNumber(decimal: entity.totalAmount))
        self.currency = entity.currency
    }

    /// Direct initializer (for backward compatibility)
    init(category: PaymentCategory, totalAmount: Double, currency: Currency) {
        self.category = category
        self.totalAmount = totalAmount
        self.currency = currency
    }
}
