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

    /// Schedule notifications for a reminder using custom notification settings
    func scheduleReminderNotifications(reminderId: UUID, title: String, dueDate: Date, notificationSettings: NotificationSettings)

    /// Cancel all notifications for a reminder
    func cancelReminderNotifications(reminderId: UUID)
    
    /// Debug function to check pending notifications
    func debugPendingNotifications() async
}

/// UserNotifications implementation of NotificationDataSource
@MainActor
final class UserNotificationsDataSource: NSObject, NotificationDataSource, UNUserNotificationCenterDelegate {
    private static let logCategory = "UserNotificationsDataSource"

    private let log: DomainLogWriter
    private let genericScheduler: GenericNotificationScheduler

    init(log: DomainLogWriter) {
        self.log = log
        self.genericScheduler = GenericNotificationScheduler(log: log)
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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] _, error in
            if let error {
                Task { @MainActor in
                    self?.log.error("Failed to request notification authorization: \(error.localizedDescription)", category: Self.logCategory)
                }
            }
        }
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

        cancelNotifications(paymentId: paymentId)
        
        // Use generic scheduler with payment-specific content builder
        let contentBuilder = PaymentNotificationContentBuilder(
            paymentName: name,
            amount: amount,  
            currencySymbol: currencySymbol
        )
        
        // Standard payment notification days: [3, 2, 1, 0]
        let notificationDays = [3, 2, 1, 0]
        let scheduler = genericScheduler
        Task { @MainActor in
            await scheduler.scheduleNotifications(
                entityId: paymentId,
                title: name,
                dueDate: dueDate,
                notificationDays: notificationDays,
                contentBuilder: contentBuilder
            )
        }
    }

    func cancelNotifications(paymentId: UUID) {
        let identifiers = LocalNotificationIdentifiers.allPaymentCancellationIdentifiers(entityId: paymentId)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Reminder notifications

    func scheduleReminderNotifications(reminderId: UUID, title: String, dueDate: Date, notificationSettings: NotificationSettings) {
        cancelReminderNotifications(reminderId: reminderId)
        
        // Use generic scheduler with reminder-specific content builder
        let contentBuilder = ReminderNotificationContentBuilder(
            reminderTitle: title,
            dueDate: dueDate
        )
        
        // Use customizable notification days from settings
        let notificationDays = notificationSettings.allNotificationDays
        let scheduler = genericScheduler
        Task { @MainActor in
            await scheduler.scheduleNotifications(
                entityId: reminderId,
                title: title,
                dueDate: dueDate,
                notificationDays: notificationDays,
                contentBuilder: contentBuilder
            )
        }
    }

    func cancelReminderNotifications(reminderId: UUID) {
        let identifiers = LocalNotificationIdentifiers.allReminderCancellationIdentifiers(entityId: reminderId)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        log.info("🗑️ Cancelled reminder notifications for ID: \(reminderId)", category: Self.logCategory)
    }
    
    func debugPendingNotifications() async {
        let pendingRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        log.info("🔍 Total pending notifications: \(pendingRequests.count)", category: Self.logCategory)
        
        let reminderNotifications = pendingRequests.filter { LocalNotificationIdentifiers.isReminderNotificationIdentifier($0.identifier) }
        let paymentNotifications = pendingRequests.filter { LocalNotificationIdentifiers.isPaymentNotificationIdentifier($0.identifier) }
        
        log.info("📋 Reminder notifications: \(reminderNotifications.count)", category: Self.logCategory)
        log.info("💰 Payment notifications: \(paymentNotifications.count)", category: Self.logCategory)
        
        for request in reminderNotifications {
            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                log.info("  - \(request.identifier): \(request.content.title) - \(request.content.subtitle)", category: Self.logCategory)
                log.info("    Trigger date: \(trigger.dateComponents)", category: Self.logCategory)
            }
        }
    }
}
