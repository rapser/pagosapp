//
//  ReminderNotificationContentBuilder.swift
//  pagosApp
//
//  Reminder-specific notification content builder.
//

import Foundation
import UserNotifications

/// Content builder for reminder notifications
struct ReminderNotificationContentBuilder: NotificationContentBuilder {
    let reminderTitle: String
    let dueDate: Date

    func buildContent(
        daysUntilDue: Int,
        title: String,
        timeOfDay: TimeOfDay?
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = L10n.LocalNotifications.Reminder.title
        content.sound = .default

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.locale = .current
        dateFormatter.timeZone = .current

        if daysUntilDue == 0 {
            content.subtitle = reminderTitle
            content.body = L10n.LocalNotifications.Reminder.bodySameDay(reminderTitle)
        } else if daysUntilDue >= 30 {
            content.subtitle = L10n.LocalNotifications.Reminder.subtitleMonth(reminderTitle)
            content.body = L10n.LocalNotifications.Reminder.bodyWithDate(
                reminderTitle,
                dateFormatter.string(from: dueDate)
            )
        } else if daysUntilDue >= 14 {
            content.subtitle = L10n.LocalNotifications.Reminder.subtitleTwoWeeks(reminderTitle)
            content.body = L10n.LocalNotifications.Reminder.bodyWithDate(
                reminderTitle,
                dateFormatter.string(from: dueDate)
            )
        } else if daysUntilDue >= 7 {
            content.subtitle = L10n.LocalNotifications.Reminder.subtitleWeek(reminderTitle)
            content.body = L10n.LocalNotifications.Reminder.bodyWithDate(
                reminderTitle,
                dateFormatter.string(from: dueDate)
            )
        } else if daysUntilDue == 1 {
            content.subtitle = L10n.LocalNotifications.Reminder.subtitleOneDay(reminderTitle)
            content.body = L10n.LocalNotifications.Reminder.bodyWithDate(
                reminderTitle,
                dateFormatter.string(from: dueDate)
            )
        } else {
            content.subtitle = L10n.LocalNotifications.Reminder.subtitleNDays(daysUntilDue, reminderTitle)
            content.body = L10n.LocalNotifications.Reminder.bodyWithDate(
                reminderTitle,
                dateFormatter.string(from: dueDate)
            )
        }

        return content
    }

    func createIdentifier(
        entityId: UUID,
        daysUntilDue: Int,
        timeOfDay: TimeOfDay?
    ) -> String {
        LocalNotificationIdentifiers.identifier(
            kind: .reminder,
            entityId: entityId,
            daysUntilDue: daysUntilDue,
            timeOfDay: timeOfDay
        )
    }
}
