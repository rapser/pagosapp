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
            logger.info("🚫 Payment \(name) is already paid, cancelling notifications")
            cancelNotifications(paymentId: paymentId)
            return
        }

        // Check authorization status before scheduling
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

                    // Create the full date with time (3:00 PM) - TEMPORAL PARA PRUEBAS
                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: notificationDate)
                    dateComponents.hour = 9
                    dateComponents.minute = 0
                    dateComponents.second = 0

                    guard let notificationDateTime = calendar.date(from: dateComponents) else {
                        continue
                    }

                    // Check if notification time has passed
                    if notificationDateTime <= now {
                        // Special case: if it's the same day (daysBefore == 0) and we're past 3 PM,
                        // schedule an immediate notification (5 seconds from now) as a fallback
                        if daysBefore == 0 && calendar.isDate(dueDate, inSameDayAs: now) {
                            self.logger.warning("⚠️ Payment \(name) vence hoy y ya pasó la hora de notificación (3 PM). Programando notificación inmediata como fallback")
                            
                            let immediateContent = UNMutableNotificationContent()
                            immediateContent.title = "Recordatorio de Pago"
                            immediateContent.subtitle = "¡Hoy vence \(name)!"
                            immediateContent.body = "No olvides pagar \(currencySymbol)\(String(format: "%.2f", amount))."
                            immediateContent.sound = .default
                            
                            // Schedule immediate notification (5 seconds from now)
                            let immediateTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                            let immediateIdentifier = "\(paymentId.uuidString)-0days-immediate"
                            let immediateRequest = UNNotificationRequest(identifier: immediateIdentifier, content: immediateContent, trigger: immediateTrigger)
                            
                            Task {
                                do {
                                    try await UNUserNotificationCenter.current().add(immediateRequest)
                                    scheduledCount += 1
                                    self.logger.info("✅ Scheduled immediate notification for \(name) (due today, past 3 PM)")
                                } catch {
                                    self.logger.error("❌ Failed to schedule immediate notification for \(name): \(error.localizedDescription)")
                                }
                            }
                        } else {
                            self.logger.info("⏭️ Skipping notification for \(name) - \(daysBefore) days before (already passed: \(notificationDateTime))")
                        }
                        continue
                    }

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

                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                    let identifier = "\(paymentId.uuidString)-\(daysBefore)days"
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                    Task {
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
                }
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
        logger.info("🚫 Cancelled notifications for payment: \(paymentId)")
    }
}
