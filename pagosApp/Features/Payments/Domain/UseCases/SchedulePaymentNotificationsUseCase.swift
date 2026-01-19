//
//  SchedulePaymentNotificationsUseCase.swift
//  pagosApp
//
//  Use Case for scheduling payment notifications
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

/// Use case for scheduling local notifications for payments
final class SchedulePaymentNotificationsUseCase {
    private let notificationDataSource: NotificationDataSource
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "SchedulePaymentNotificationsUseCase")

    init(notificationDataSource: NotificationDataSource) {
        self.notificationDataSource = notificationDataSource
    }

    /// Schedule notifications for a payment
    /// - Parameter payment: The payment to schedule notifications for
    @MainActor
    func execute(_ payment: Payment) {
        logger.info("📅 Scheduling notifications for payment: \(payment.name)")

        // Get currency symbol
        let currencySymbol = payment.currency.symbol

        // Schedule notifications
        notificationDataSource.scheduleNotifications(
            paymentId: payment.id,
            name: payment.name,
            amount: NSDecimalNumber(decimal: payment.amount).doubleValue,
            currencySymbol: currencySymbol,
            dueDate: payment.dueDate,
            isPaid: payment.isPaid
        )

        logger.info("✅ Notifications scheduled for payment: \(payment.name)")
    }

    /// Cancel notifications for a payment
    /// - Parameter paymentId: The ID of the payment to cancel notifications for
    @MainActor
    func cancel(for paymentId: UUID) {
        logger.info("🚫 Cancelling notifications for payment: \(paymentId)")
        notificationDataSource.cancelNotifications(paymentId: paymentId)
        logger.info("✅ Notifications cancelled for payment: \(paymentId)")
    }

    /// Reschedule notifications for all payments (useful after app updates or permission changes)
    /// - Parameter payments: Array of payments to reschedule
    @MainActor
    func rescheduleAll(_ payments: [Payment]) {
        logger.info("🔄 Rescheduling notifications for \(payments.count) payments")

        for payment in payments {
            execute(payment)
        }

        logger.info("✅ Rescheduled notifications for \(payments.count) payments")
    }
}
