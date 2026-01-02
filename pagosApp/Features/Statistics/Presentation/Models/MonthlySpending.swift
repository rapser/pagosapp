//
//  MonthlySpending.swift
//  pagosApp
//
//  Presentation model for monthly spending (for Charts)
//  Clean Architecture: Presentation layer - UI state model
//

import Foundation

/// Presentation model for monthly spending statistics (used in Charts)
struct MonthlySpending: Identifiable {
    let id = UUID()
    let month: Date
    let totalAmount: Double
    let currency: Currency

    /// Initialize from domain entity
    init(from entity: MonthlyStatsEntity) {
        self.month = entity.month
        self.totalAmount = entity.totalAmount
        self.currency = entity.currency
    }

    /// Direct initializer (for backward compatibility)
    init(month: Date, totalAmount: Double, currency: Currency) {
        self.month = month
        self.totalAmount = totalAmount
        self.currency = currency
    }
}
