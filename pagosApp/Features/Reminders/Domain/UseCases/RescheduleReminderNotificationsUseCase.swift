//
//  RescheduleReminderNotificationsUseCase.swift
//  pagosApp
//
//  Use Case for rescheduling reminder notifications
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case for rescheduling local notifications for reminders
final class RescheduleReminderNotificationsUseCase {
    private static let logCategory = "RescheduleReminderNotificationsUseCase"

    private let notificationDataSource: NotificationDataSource
    private let log: DomainLogWriter

    init(notificationDataSource: NotificationDataSource, log: DomainLogWriter) {
        self.notificationDataSource = notificationDataSource
        self.log = log
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
        log.info("📅 Rescheduling notifications for \(reminders.count) reminders", category: Self.logCategory)
        let activeReminders = reminders.filter { !$0.isCompleted }
        log.info("📋 Active reminders (not completed): \(activeReminders.count)", category: Self.logCategory)
        
        for reminder in reminders {
            execute(reminder)
        }
        
        log.info("✅ Finished rescheduling all reminder notifications", category: Self.logCategory)
    }
}