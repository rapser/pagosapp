//
//  NotificationDataSource.swift
//  pagosApp
//
//  Platform DataSource for local notifications (UserNotifications wrapper)
//  Clean Architecture - Data Layer (Platform)
//

import Foundation
import UserNotifications
import OSLog

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
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "NotificationDataSource")
    private let genericScheduler = GenericNotificationScheduler()

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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                Task { @MainActor in
                    self.logger.error("Failed to request notification authorization: \(error.localizedDescription)")
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
        
        Task {
            await genericScheduler.scheduleNotifications(
                entityId: paymentId,
                title: name,
                dueDate: dueDate,
                notificationDays: notificationDays,
                contentBuilder: contentBuilder
            )
        }
    }

    func cancelNotifications(paymentId: UUID) {
        let identifiers = [
            "\(paymentId.uuidString)-0days-9am",      // Same day 9 AM
            "\(paymentId.uuidString)-0days-2pm",      // Same day 2 PM
            "\(paymentId.uuidString)-1days",          // 1 day before
            "\(paymentId.uuidString)-2days",          // 2 days before
            "\(paymentId.uuidString)-3days",          // 3 days before
            "\(paymentId.uuidString)-0days",          // Legacy identifier (por si quedó alguno)
            "\(paymentId.uuidString)-0days-immediate" // Legacy identifier (por si quedó alguno)
        ]
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
        
        Task {
            await genericScheduler.scheduleNotifications(
                entityId: reminderId,
                title: title,
                dueDate: dueDate,
                notificationDays: notificationDays,
                contentBuilder: contentBuilder
            )
        }
    }

    func cancelReminderNotifications(reminderId: UUID) {
        let identifiers = [
            "reminder-\(reminderId.uuidString)-0days-9am",
            "reminder-\(reminderId.uuidString)-0days-2pm",
            "reminder-\(reminderId.uuidString)-1days",
            "reminder-\(reminderId.uuidString)-2days",
            "reminder-\(reminderId.uuidString)-3days",
            "reminder-\(reminderId.uuidString)-4days",  // Legacy (for old 5-day system)
            "reminder-\(reminderId.uuidString)-5days",  // Legacy (for old 5-day system)
            "reminder-\(reminderId.uuidString)-7days",  // 1 week before
            "reminder-\(reminderId.uuidString)-14days", // 2 weeks before  
            "reminder-\(reminderId.uuidString)-30days"  // 1 month before
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        logger.info("🗑️ Cancelled reminder notifications for ID: \(reminderId)")
    }
    
    func debugPendingNotifications() async {
        let pendingRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        logger.info("🔍 Total pending notifications: \(pendingRequests.count)")
        
        let reminderNotifications = pendingRequests.filter { $0.identifier.contains("reminder-") }
        let paymentNotifications = pendingRequests.filter { !$0.identifier.contains("reminder-") }
        
        logger.info("📋 Reminder notifications: \(reminderNotifications.count)")
        logger.info("💰 Payment notifications: \(paymentNotifications.count)")
        
        for request in reminderNotifications {
            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                logger.info("  - \(request.identifier): \(request.content.title) - \(request.content.subtitle)")
                logger.info("    Trigger date: \(trigger.dateComponents)")
            }
        }
    }
}
