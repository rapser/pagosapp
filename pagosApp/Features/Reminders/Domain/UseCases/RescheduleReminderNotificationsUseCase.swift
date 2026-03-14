//
//  RescheduleReminderNotificationsUseCase.swift
//  pagosApp
//
//  Use Case for rescheduling reminder notifications
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

/// Use case for rescheduling local notifications for reminders
final class RescheduleReminderNotificationsUseCase {
    private let notificationDataSource: NotificationDataSource
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "RescheduleReminderNotificationsUseCase")

    init(notificationDataSource: NotificationDataSource) {
        self.notificationDataSource = notificationDataSource
    }

    @MainActor
    func execute(_ reminder: Reminder) {
        guard !reminder.isCompleted else {
            // Cancel notifications for completed reminders
            notificationDataSource.cancelReminderNotifications(reminderId: reminder.id)
            return
        }
        
        notificationDataSource.scheduleReminderNotifications(
            reminderId: reminder.id,
            title: reminder.title,
            dueDate: reminder.dueDate,
            notificationSettings: reminder.notificationSettings
        )
    }

    @MainActor
    func cancel(for reminderId: UUID) {
        notificationDataSource.cancelReminderNotifications(reminderId: reminderId)
    }

    @MainActor
    func rescheduleAll(_ reminders: [Reminder]) {
        logger.info("📅 Rescheduling notifications for \(reminders.count) reminders")
        let activeReminders = reminders.filter { !$0.isCompleted }
        logger.info("📋 Active reminders (not completed): \(activeReminders.count)")
        
        for reminder in reminders {
            execute(reminder)
        }
        
        logger.info("✅ Finished rescheduling all reminder notifications")
    }
}