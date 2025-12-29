//
//  PaymentUI.swift
//  pagosApp
//
//  Presentation model for Payment display
//  Clean Architecture: Presentation layer - UI representation model
//

import Foundation
import SwiftUI

/// UI representation of a Payment
/// Contains display-specific logic and computed properties for the view layer
struct PaymentUI: Identifiable, Equatable {
    let id: UUID
    let name: String
    let amount: Double
    let currency: Currency
    let dueDate: Date
    let isPaid: Bool
    let category: PaymentCategory
    let eventIdentifier: String?
    let syncStatus: SyncStatus
    let lastSyncedAt: Date?

    // MARK: - Computed Properties for UI

    /// Formatted amount with currency symbol
    var formattedAmount: String {
        "\(currency.symbol) \(String(format: "%.2f", amount))"
    }

    /// Formatted date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dueDate)
    }

    /// Color for status indicator
    var statusColor: Color {
        isPaid ? Color("AppSuccess") : Color("AppTextSecondary")
    }

    /// Icon for payment status
    var statusIcon: String {
        isPaid ? "checkmark.circle.fill" : "circle"
    }

    /// Opacity for display (paid items are less prominent)
    var displayOpacity: Double {
        isPaid ? 0.7 : 1.0
    }

    /// Whether the payment is overdue
    var isOverdue: Bool {
        !isPaid && dueDate < Date()
    }

    /// Display color based on payment state
    var displayColor: Color {
        if isPaid {
            return Color("AppSuccess")
        } else if isOverdue {
            return Color.red
        } else {
            return Color("AppTextPrimary")
        }
    }
}

// MARK: - Mapper from Domain to Presentation

extension PaymentUI {
    /// Create PaymentUI from Domain Payment
    static func from(domain payment: Payment) -> PaymentUI {
        return PaymentUI(
            id: payment.id,
            name: payment.name,
            amount: payment.amount,
            currency: payment.currency,
            dueDate: payment.dueDate,
            isPaid: payment.isPaid,
            category: payment.category,
            eventIdentifier: payment.eventIdentifier,
            syncStatus: payment.syncStatus,
            lastSyncedAt: payment.lastSyncedAt
        )
    }

    /// Convert back to Domain Payment
    func toDomain() -> Payment {
        return Payment(
            id: id,
            name: name,
            amount: amount,
            currency: currency,
            dueDate: dueDate,
            isPaid: isPaid,
            category: category,
            eventIdentifier: eventIdentifier,
            syncStatus: syncStatus,
            lastSyncedAt: lastSyncedAt
        )
    }
}

// MARK: - Array Extensions

extension Array where Element == Payment {
    /// Convert array of Domain Payments to PaymentUI
    func toUI() -> [PaymentUI] {
        return self.map { PaymentUI.from(domain: $0) }
    }
}

extension Array where Element == PaymentUI {
    /// Convert array of PaymentUI to Domain Payments
    func toDomain() -> [Payment] {
        return self.map { $0.toDomain() }
    }
}
