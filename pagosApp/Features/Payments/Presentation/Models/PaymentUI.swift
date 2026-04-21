//
//  PaymentUI.swift
//  pagosApp
//
//  Presentation model for Payment display
//  Clean Architecture: Presentation layer - UI representation model
//

import Foundation

/// Presentation-agnostic color token; map to `SwiftUI.Color` in views.
enum PaymentColorToken: Equatable, Sendable {
    case appSuccess
    case appTextSecondary
    case appTextPrimary
    case overdue
}

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

    /// Color token for status indicator
    var statusColorToken: PaymentColorToken {
        isPaid ? .appSuccess : .appTextSecondary
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
    /// A payment is considered overdue only after midnight of the due date
    /// (i.e., if due date is Jan 15, it becomes overdue on Jan 16 at 00:00:00)
    var isOverdue: Bool {
        guard !isPaid else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDateStart = calendar.startOfDay(for: dueDate)
        // Overdue only if due date is before today (not same day)
        return dueDateStart < today
    }

    /// Display color token based on payment state
    var displayColorToken: PaymentColorToken {
        if isPaid {
            return .appSuccess
        } else if isOverdue {
            return .overdue
        } else {
            return .appTextPrimary
        }
    }
}
