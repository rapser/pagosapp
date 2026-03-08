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

    /// Schedule notifications for a reminder (from 5 days before: 5, 4, 3, 2, 1 days before + same day 9 AM and 2 PM)
    func scheduleReminderNotifications(reminderId: UUID, title: String, dueDate: Date)

    /// Cancel all notifications for a reminder
    func cancelReminderNotifications(reminderId: UUID)
}

/// UserNotifications implementation of NotificationDataSource
@MainActor
final class UserNotificationsDataSource: NSObject, NotificationDataSource, UNUserNotificationCenterDelegate {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "NotificationDataSource")

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
                    self.logger.error("❌ Failed to request notification authorization: \(error.localizedDescription)")
                }
            } else {
                Task { @MainActor in
                    self.logger.info("✅ Notification authorization granted: \(granted)")
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
            logger.info("🚫 Payment \(name) is already paid, cancelling all pending notifications (including same-day 9 AM and 2 PM notifications)")
            cancelNotifications(paymentId: paymentId)
            return
        }

        // Always cancel existing notifications first to ensure clean state
        // This is especially important when updating payment dates
        logger.info("🔄 Cancelling existing notifications for \(name) before rescheduling")
        cancelNotifications(paymentId: paymentId)

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self = self else { return }

            Task { @MainActor in
                guard settings.authorizationStatus == .authorized else {
                    self.logger.warning("⚠️ Notifications not authorized (status: \(settings.authorizationStatus.rawValue)). Cannot schedule notifications for \(name)")
                    return
                }

                let calendar = Calendar.current
                let now = Date()
                let notificationDays = [0, 1, 2] // Same day, 1 day before, 2 days before
                var scheduledCount = 0

                for daysBefore in notificationDays {
                    guard let notificationDate = calendar.date(byAdding: .day, value: -daysBefore, to: dueDate) else {
                        continue
                    }

                    // For same day (daysBefore == 0), schedule two notifications: 9 AM and 2 PM
                    if daysBefore == 0 {
                        // Schedule 9 AM notification
                        var dateComponents9AM = calendar.dateComponents([.year, .month, .day], from: notificationDate)
                        dateComponents9AM.hour = 9
                        dateComponents9AM.minute = 0
                        dateComponents9AM.second = 0

                        guard let notificationDateTime9AM = calendar.date(from: dateComponents9AM) else {
                            continue
                        }

                        if notificationDateTime9AM > now {
                            let identifier9AM = "\(paymentId.uuidString)-0days-9am"
                            let content9AM = UNMutableNotificationContent()
                            content9AM.title = "Recordatorio de Pago"
                            content9AM.subtitle = "¡Hoy vence \(name)!"
                            content9AM.body = "No olvides pagar \(currencySymbol)\(String(format: "%.2f", amount))."
                            content9AM.sound = .default

                            let trigger9AM = UNCalendarNotificationTrigger(dateMatching: dateComponents9AM, repeats: false)
                            let request9AM = UNNotificationRequest(identifier: identifier9AM, content: content9AM, trigger: trigger9AM)

                            do {
                                try await UNUserNotificationCenter.current().add(request9AM)
                                scheduledCount += 1
                                self.logger.info("✅ Scheduled 9 AM notification for \(name) - due today (notification: \(notificationDateTime9AM))")
                            } catch {
                                self.logger.error("❌ Failed to schedule 9 AM notification for \(name): \(error.localizedDescription)")
                            }
                        } else {
                            self.logger.info("⏭️ Skipping 9 AM notification for \(name) - already passed")
                        }

                        // Schedule 2 PM notification
                        var dateComponents2PM = calendar.dateComponents([.year, .month, .day], from: notificationDate)
                        dateComponents2PM.hour = 14
                        dateComponents2PM.minute = 0
                        dateComponents2PM.second = 0

                        guard let notificationDateTime2PM = calendar.date(from: dateComponents2PM) else {
                            continue
                        }

                        if notificationDateTime2PM > now {
                            let identifier2PM = "\(paymentId.uuidString)-0days-2pm"
                            let content2PM = UNMutableNotificationContent()
                            content2PM.title = "Recordatorio de Pago"
                            content2PM.subtitle = "¡Hoy vence \(name)!"
                            content2PM.body = "No olvides pagar \(currencySymbol)\(String(format: "%.2f", amount))."
                            content2PM.sound = .default

                            let trigger2PM = UNCalendarNotificationTrigger(dateMatching: dateComponents2PM, repeats: false)
                            let request2PM = UNNotificationRequest(identifier: identifier2PM, content: content2PM, trigger: trigger2PM)

                            do {
                                try await UNUserNotificationCenter.current().add(request2PM)
                                scheduledCount += 1
                                self.logger.info("✅ Scheduled 2 PM notification for \(name) - due today (notification: \(notificationDateTime2PM))")
                            } catch {
                                self.logger.error("❌ Failed to schedule 2 PM notification for \(name): \(error.localizedDescription)")
                            }
                        } else {
                            self.logger.info("⏭️ Skipping 2 PM notification for \(name) - already passed")
                        }
                    } else {
                        // For 1 day before and 2 days before, schedule only 9 AM notification
                        var dateComponents = calendar.dateComponents([.year, .month, .day], from: notificationDate)
                        dateComponents.hour = 9
                        dateComponents.minute = 0
                        dateComponents.second = 0

                        guard let notificationDateTime = calendar.date(from: dateComponents) else {
                            continue
                        }

                        // Check if notification time has passed
                        if notificationDateTime <= now {
                            self.logger.info("⏭️ Skipping notification for \(name) - \(daysBefore) days before (already passed: \(notificationDateTime))")
                            continue
                        }

                        let identifier = "\(paymentId.uuidString)-\(daysBefore)days"
                        let content = UNMutableNotificationContent()
                        content.title = "Recordatorio de Pago"
                        content.subtitle = "Vence en \(daysBefore) día(s): \(name)"
                        content.body = "Recuerda que tienes un pago de \(currencySymbol)\(String(format: "%.2f", amount)) pendiente."
                        content.sound = .default

                        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                        do {
                            try await UNUserNotificationCenter.current().add(request)
                            scheduledCount += 1
                            self.logger.info("✅ Scheduled notification for \(name) - \(daysBefore) days before (due: \(dueDate), notification: \(notificationDateTime))")
                        } catch {
                            self.logger.error("❌ Failed to schedule notification for \(name) (\(daysBefore) days before): \(error.localizedDescription)")
                        }
                    }
                }

                if scheduledCount == 0 {
                    self.logger.warning("⚠️ No notifications scheduled for \(name) - all notification times have already passed")
                } else {
                    self.logger.info("✅ Successfully scheduled \(scheduledCount) notification(s) for \(name) with new due date: \(dueDate)")
                }
            }
        }
    }

    func cancelNotifications(paymentId: UUID) {
        let identifiers = [
            "\(paymentId.uuidString)-0days-9am",      // Same day 9 AM
            "\(paymentId.uuidString)-0days-2pm",      // Same day 2 PM
            "\(paymentId.uuidString)-1days",          // 1 day before
            "\(paymentId.uuidString)-2days",          // 2 days before
            "\(paymentId.uuidString)-0days",          // Legacy identifier (por si quedó alguno)
            "\(paymentId.uuidString)-0days-immediate" // Legacy identifier (por si quedó alguno)
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        self.logger.info("🚫 Cancelled notifications for payment: \(paymentId)")
    }

    // MARK: - Reminder notifications (from 5 days before: 0=same day, 1..5 days before; same day 9 AM and 2 PM)

    func scheduleReminderNotifications(reminderId: UUID, title: String, dueDate: Date) {
        cancelReminderNotifications(reminderId: reminderId)

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                guard settings.authorizationStatus == .authorized else { return }

                let calendar = Calendar.current
                let now = Date()
                let notificationDays = [0, 1, 2, 3, 4, 5] // Same day + 1 to 5 days before (reminders start earlier than payments)
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium

                for daysBefore in notificationDays {
                    guard let notificationDate = calendar.date(byAdding: .day, value: -daysBefore, to: dueDate) else { continue }

                    if daysBefore == 0 {
                        for (hour, suffix) in [(9, "9am"), (14, "2pm")] {
                            var comp = calendar.dateComponents([.year, .month, .day], from: notificationDate)
                            comp.hour = hour
                            comp.minute = 0
                            comp.second = 0
                            guard let triggerDate = calendar.date(from: comp), triggerDate > now else { continue }
                            let id = "reminder-\(reminderId.uuidString)-0days-\(suffix)"
                            let content = UNMutableNotificationContent()
                            content.title = "Recordatorio"
                            content.subtitle = title
                            content.body = "Hoy: \(title)."
                            content.sound = .default
                            let trigger = UNCalendarNotificationTrigger(dateMatching: comp, repeats: false)
                            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                            try? await UNUserNotificationCenter.current().add(request)
                        }
                    } else {
                        var comp = calendar.dateComponents([.year, .month, .day], from: notificationDate)
                        comp.hour = 9
                        comp.minute = 0
                        comp.second = 0
                        guard let triggerDate = calendar.date(from: comp), triggerDate > now else { continue }
                        let id = "reminder-\(reminderId.uuidString)-\(daysBefore)days"
                        let content = UNMutableNotificationContent()
                        content.title = "Recordatorio"
                        content.subtitle = "En \(daysBefore) día(s): \(title)"
                        content.body = "\(title) — \(dateFormatter.string(from: dueDate))"
                        content.sound = .default
                        let trigger = UNCalendarNotificationTrigger(dateMatching: comp, repeats: false)
                        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                        try? await UNUserNotificationCenter.current().add(request)
                    }
                }
            }
        }
    }

    func cancelReminderNotifications(reminderId: UUID) {
        let identifiers = [
            "reminder-\(reminderId.uuidString)-0days-9am",
            "reminder-\(reminderId.uuidString)-0days-2pm",
            "reminder-\(reminderId.uuidString)-1days",
            "reminder-\(reminderId.uuidString)-2days",
            "reminder-\(reminderId.uuidString)-3days",
            "reminder-\(reminderId.uuidString)-4days",
            "reminder-\(reminderId.uuidString)-5days"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
