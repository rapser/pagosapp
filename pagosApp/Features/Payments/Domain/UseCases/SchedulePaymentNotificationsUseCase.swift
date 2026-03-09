//
//  SchedulePaymentNotificationsUseCase.swift
//  pagosApp
//
//  Use Case for scheduling payment notifications
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case for scheduling local notifications for payments
final class SchedulePaymentNotificationsUseCase {
    private let notificationDataSource: NotificationDataSource

    init(notificationDataSource: NotificationDataSource) {
        self.notificationDataSource = notificationDataSource
    }

    @MainActor
    func execute(_ payment: Payment) {
        let currencySymbol = payment.currency.symbol
        notificationDataSource.scheduleNotifications(
            paymentId: payment.id,
            name: payment.name,
            amount: NSDecimalNumber(decimal: payment.amount).doubleValue,
            currencySymbol: currencySymbol,
            dueDate: payment.dueDate,
            isPaid: payment.isPaid
        )
    }

    @MainActor
    func cancel(for paymentId: UUID) {
        notificationDataSource.cancelNotifications(paymentId: paymentId)
    }

    @MainActor
    func rescheduleAll(_ payments: [Payment]) {
        for payment in payments {
            execute(payment)
        }
    }
}
