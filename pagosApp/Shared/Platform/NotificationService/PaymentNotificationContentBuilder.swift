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
        content.title = "Recordatorio de Pago"
        content.sound = .default
        
        if daysUntilDue == 0 {
            // Same day notifications
            content.subtitle = "¡Hoy vence \(paymentName)!"
            content.body = "No olvides pagar \(currencySymbol)\(String(format: "%.2f", amount))."
        } else {
            // Days before notifications
            let dayText = daysUntilDue == 1 ? "día" : "días"
            content.subtitle = "En \(daysUntilDue) \(dayText): \(paymentName)"
            content.body = "Monto: \(currencySymbol)\(String(format: "%.2f", amount))"
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
}