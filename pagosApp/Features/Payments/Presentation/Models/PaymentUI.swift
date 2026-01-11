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
struct PaymentUI: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let amount: Double  // Double for UI binding (converted from Decimal in Domain)
    let currency: Currency
    let dueDate: Date
    let isPaid: Bool
    let category: PaymentCategory
    let eventIdentifier: String?
    let syncStatus: SyncStatus
    let lastSyncedAt: Date?
    let groupId: UUID?

    // MARK: - Computed Properties for UI

    /// Formatted amount with currency symbol
    var formattedAmount: String {
        "\(currency.symbol) \(String(format: "%.2f", amount))"
    }

    /// Formatted date for display
    var formattedDate: String {
        DateFormattingService.formatMedium(dueDate)
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
