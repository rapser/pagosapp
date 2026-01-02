//
//  NotificationDataSource.swift
//  pagosApp
//
//  Platform DataSource for local notifications (UserNotifications wrapper)
//  Clean Architecture - Data Layer (Platform)
//

import Foundation
import UserNotifications

/// Protocol for notification operations
@MainActor
protocol NotificationDataSource {
    /// Request notification authorization from user
    func requestAuthorization()

    /// Schedule notifications for a payment
    func scheduleNotifications(paymentId: UUID, name: String, amount: Double, currencySymbol: String, dueDate: Date, isPaid: Bool)

    /// Cancel all notifications for a payment
    func cancelNotifications(paymentId: UUID)
}

/// UserNotifications implementation of NotificationDataSource
@MainActor
final class UserNotificationsDataSource: NSObject, NotificationDataSource, UNUserNotificationCenterDelegate {
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // MARK: - NotificationDataSource

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    func scheduleNotifications(
        paymentId: UUID,
        name: String,
        amount: Double,
        currencySymbol: String,
        dueDate: Date,
        isPaid: Bool
    ) {
        guard !isPaid else {
            cancelNotifications(paymentId: paymentId)
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let notificationDays = [0, 1, 2] // Same day, 1 day before, 2 days before

        for daysBefore in notificationDays {
            guard let notificationDate = calendar.date(byAdding: .day, value: -daysBefore, to: dueDate) else { continue }

            if notificationDate >= calendar.startOfDay(for: now) {
                let content = UNMutableNotificationContent()
                content.title = "Recordatorio de Pago"

                if daysBefore == 0 {
                    content.subtitle = "¡Hoy vence \(name)!"
                    content.body = "No olvides pagar \(currencySymbol)\(String(format: "%.2f", amount))."
                } else {
                    content.subtitle = "Vence en \(daysBefore) día(s): \(name)"
                    content.body = "Recuerda que tienes un pago de \(currencySymbol)\(String(format: "%.2f", amount)) pendiente."
                }
                content.sound = .default

                var dateComponents = calendar.dateComponents([.year, .month, .day], from: notificationDate)
                dateComponents.hour = 9
                dateComponents.minute = 0
                dateComponents.second = 0

                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let identifier = "\(paymentId.uuidString)-\(daysBefore)days"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request) { _ in }
            }
        }
    }

    func cancelNotifications(paymentId: UUID) {
        let identifiers = [
            "\(paymentId.uuidString)-0days",
            "\(paymentId.uuidString)-1days",
            "\(paymentId.uuidString)-2days"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
