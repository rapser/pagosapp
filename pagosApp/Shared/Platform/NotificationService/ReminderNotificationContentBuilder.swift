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
        content.title = "Recordatorio"
        content.sound = .default
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        if daysUntilDue == 0 {
            // Same day notifications
            content.subtitle = reminderTitle  
            content.body = "Hoy: \(reminderTitle)."
        } else {
            // Days before notifications - customize subtitle based on time frame
            if daysUntilDue >= 30 {
                content.subtitle = "En 1 mes: \(reminderTitle)"
            } else if daysUntilDue >= 14 {
                content.subtitle = "En 2 semanas: \(reminderTitle)"
            } else if daysUntilDue >= 7 {
                content.subtitle = "En 1 semana: \(reminderTitle)"
            } else {
                content.subtitle = "En \(daysUntilDue) día(s): \(reminderTitle)"
            }
            
            content.body = "\(reminderTitle) — \(dateFormatter.string(from: dueDate))"
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