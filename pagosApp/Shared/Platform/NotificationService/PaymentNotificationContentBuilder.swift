//
//  PaymentNotificationContentBuilder.swift
//  pagosApp
//
//  Payment-specific notification content builder.
//

import Foundation
import UserNotifications

/// Content builder for payment notifications
struct PaymentNotificationContentBuilder: NotificationContentBuilder {
    let paymentName: String
    let amount: Double
    let currencySymbol: String

    func buildContent(
        daysUntilDue: Int,
        title: String,
        timeOfDay: TimeOfDay?
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = L10n.LocalNotifications.Payment.title
        content.sound = .default

        let amountFormatted = Self.formattedAmount(currencySymbol: currencySymbol, amount: amount)

        if daysUntilDue == 0 {
            content.subtitle = L10n.LocalNotifications.Payment.subtitleSameDay(paymentName)
            content.body = L10n.LocalNotifications.Payment.bodySameDay(amountFormatted)
        } else if daysUntilDue == 1 {
            content.subtitle = L10n.LocalNotifications.Payment.subtitleOneDayBefore(paymentName)
            content.body = L10n.LocalNotifications.Payment.bodyAmount(amountFormatted)
        } else {
            content.subtitle = L10n.LocalNotifications.Payment.subtitleNDaysBefore(daysUntilDue, paymentName)
            content.body = L10n.LocalNotifications.Payment.bodyAmount(amountFormatted)
        }

        return content
    }

    func createIdentifier(
        entityId: UUID,
        daysUntilDue: Int,
        timeOfDay: TimeOfDay?
    ) -> String {
        LocalNotificationIdentifiers.identifier(
            kind: .payment,
            entityId: entityId,
            daysUntilDue: daysUntilDue,
            timeOfDay: timeOfDay
        )
    }

    private static func formattedAmount(currencySymbol: String, amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.locale = .current
        let number = NSDecimalNumber(value: amount)
        let amountPart = formatter.string(from: number) ?? String(format: "%.2f", amount)
        return "\(currencySymbol)\(amountPart)"
    }
}
