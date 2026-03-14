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

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self = self else { return }

            Task { @MainActor in
                guard settings.authorizationStatus == .authorized else { return }

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
                            } catch {
                                self.logger.error("Failed to schedule 9 AM notification: \(error.localizedDescription)")
                            }
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
                            } catch {
                                self.logger.error("Failed to schedule 2 PM notification: \(error.localizedDescription)")
                            }
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

                        if notificationDateTime <= now { continue }

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
                        } catch {
                            self.logger.error("Failed to schedule notification: \(error.localizedDescription)")
                        }
                    }
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
    }

    // MARK: - Reminder notifications (from 5 days before: 0=same day, 1..5 days before; same day 9 AM and 2 PM)

    func scheduleReminderNotifications(reminderId: UUID, title: String, dueDate: Date, notificationSettings: NotificationSettings) {
        cancelReminderNotifications(reminderId: reminderId)

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            
            Task { @MainActor in
                guard settings.authorizationStatus == .authorized else { 
                    self.logger.warning("⚠️ Notification authorization not granted for reminder notifications")
                    return 
                }

                let calendar = Calendar.current
                let now = Date()
                let notificationDays = notificationSettings.allNotificationDays // Uses new customizable settings
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                var scheduledCount = 0

                self.logger.info("📅 Scheduling reminder notifications for: \(title) due on \(dateFormatter.string(from: dueDate))")
                self.logger.info("🔔 Notification schedule: \(notificationDays) days before")

                for daysBefore in notificationDays {
                    guard let notificationDate = calendar.date(byAdding: .day, value: -daysBefore, to: dueDate) else { 
                        self.logger.error("Failed to calculate notification date for \(daysBefore) days before")
                        continue 
                    }

                    if daysBefore == 0 {
                        // Schedule two notifications for same day: 9 AM and 2 PM (like payments)
                        for (hour, suffix) in [(9, "9am"), (14, "2pm")] {
                            var comp = calendar.dateComponents([.year, .month, .day], from: notificationDate)
                            comp.hour = hour
                            comp.minute = 0
                            comp.second = 0
                            
                            guard let triggerDate = calendar.date(from: comp) else {
                                self.logger.error("Failed to create trigger date for same day \(suffix)")
                                continue 
                            }
                            
                            guard triggerDate > now else {
                                self.logger.info("Skipping past notification time: \(triggerDate)")
                                continue 
                            }
                            
                            let id = "reminder-\(reminderId.uuidString)-0days-\(suffix)"
                            let content = UNMutableNotificationContent()
                            content.title = "Recordatorio"
                            content.subtitle = title
                            content.body = "Hoy: \(title)."
                            content.sound = .default
                            
                            let trigger = UNCalendarNotificationTrigger(dateMatching: comp, repeats: false)
                            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                            
                            do {
                                try await UNUserNotificationCenter.current().add(request)
                                scheduledCount += 1
                                self.logger.info("✅ Scheduled same day reminder notification (\(suffix)) for: \(title)")
                            } catch {
                                self.logger.error("❌ Failed to schedule same day reminder notification (\(suffix)): \(error.localizedDescription)")
                            }
                        }
                    } else {
                        // Schedule notification for days before (at 9 AM)
                        var comp = calendar.dateComponents([.year, .month, .day], from: notificationDate)
                        comp.hour = 9
                        comp.minute = 0
                        comp.second = 0
                        
                        guard let triggerDate = calendar.date(from: comp) else {
                            self.logger.error("Failed to create trigger date for \(daysBefore) days before")
                            continue 
                        }
                        
                        guard triggerDate > now else {
                            self.logger.info("Skipping past notification date (\(daysBefore) days before): \(triggerDate)")
                            continue 
                        }
                        
                        let id = "reminder-\(reminderId.uuidString)-\(daysBefore)days"
                        let content = UNMutableNotificationContent()
                        content.title = "Recordatorio"
                        
                        // Customize subtitle based on time frame
                        if daysBefore >= 30 {
                            content.subtitle = "En 1 mes: \(title)"
                        } else if daysBefore >= 14 {
                            content.subtitle = "En 2 semanas: \(title)"
                        } else if daysBefore >= 7 {
                            content.subtitle = "En 1 semana: \(title)"
                        } else {
                            content.subtitle = "En \(daysBefore) día(s): \(title)"
                        }
                        
                        content.body = "\(title) — \(dateFormatter.string(from: dueDate))"
                        content.sound = .default
                        
                        let trigger = UNCalendarNotificationTrigger(dateMatching: comp, repeats: false)
                        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                        
                        do {
                            try await UNUserNotificationCenter.current().add(request)
                            scheduledCount += 1
                            self.logger.info("✅ Scheduled reminder notification (\(daysBefore) days before) for: \(title)")
                        } catch {
                            self.logger.error("❌ Failed to schedule reminder notification (\(daysBefore) days before): \(error.localizedDescription)")
                        }
                    }
                }
                
                self.logger.info("📊 Total reminder notifications scheduled: \(scheduledCount) for \(title)")
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
