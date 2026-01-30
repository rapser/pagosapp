//
//  PaymentGroup.swift
//  pagosApp
//
//  Presentation model for grouped dual-currency payments
//  Clean Architecture: Presentation layer
//

import Foundation
import SwiftUI

/// Represents a group of related payments (dual-currency credit cards)
/// Used only in PaymentsListView for visual grouping
struct PaymentGroupUI: Identifiable {
    let id: UUID  // groupId shared by both payments
    let name: String
    let penPayment: PaymentUI?
    let usdPayment: PaymentUI?
    let dueDate: Date
    let category: PaymentCategory

    // MARK: - Computed Properties

    /// Both payments are paid
    var isPaid: Bool {
        (penPayment?.isPaid ?? true) && (usdPayment?.isPaid ?? true)
    }

    /// Formatted amounts: "$10.00 - S/ 1,200.00"
    var formattedAmount: String {
        var parts: [String] = []

        if let usd = usdPayment {
            parts.append("$ \(String(format: "%.2f", usd.amount))")
        }

        if let pen = penPayment {
            parts.append("S/ \(String(format: "%.2f", pen.amount))")
        }

        return parts.joined(separator: "  -  ")
    }

    /// Formatted date
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

    /// Opacity for display
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

    /// Display color based on state
    var displayColor: Color {
        if isPaid {
            return Color("AppSuccess")
        } else if isOverdue {
            return Color.red
        } else {
            return Color("AppTextPrimary")
        }
    }

    /// Get all payment IDs in this group
    var paymentIds: [UUID] {
        var ids: [UUID] = []
        if let pen = penPayment {
            ids.append(pen.id)
        }
        if let usd = usdPayment {
            ids.append(usd.id)
        }
        return ids
    }

    // MARK: - Factory Methods

    /// Create PaymentGroup from two related payments
    static func from(penPayment: PaymentUI?, usdPayment: PaymentUI?, groupId: UUID) -> PaymentGroupUI? {
        // Use first available payment for common properties
        guard let firstPayment = penPayment ?? usdPayment else { return nil }

        return PaymentGroupUI(
            id: groupId,
            name: firstPayment.name,
            penPayment: penPayment,
            usdPayment: usdPayment,
            dueDate: firstPayment.dueDate,
            category: firstPayment.category
        )
    }
}
