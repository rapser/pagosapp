//
//  GenericNotificationScheduler.swift
//  pagosApp
//
//  Generic notification scheduling service to eliminate code duplication.
//  Replaces duplicate logic between payment and reminder notifications.
//

import Foundation
import UserNotifications
import OSLog

/// Protocol for notification content configuration
protocol NotificationContentBuilder {
    func buildContent(
        daysUntilDue: Int,
        title: String,
        timeOfDay: TimeOfDay?
    ) -> UNMutableNotificationContent
    
    func createIdentifier(
        entityId: UUID,
        daysUntilDue: Int,
        timeOfDay: TimeOfDay?
    ) -> String
}

/// Represents different times of day for notifications
enum TimeOfDay: CaseIterable {
    case morning // 9 AM
    case afternoon // 2 PM
    
    var hour: Int {
        switch self {
        case .morning: return 9
        case .afternoon: return 14
        }
    }
    
    var suffix: String {
        switch self {
        case .morning: return "9am"
        case .afternoon: return "2pm"
        }
    }
}

/// Generic notification scheduler that eliminates duplication
final class GenericNotificationScheduler {
    private let logger = Logger(subsystem: "com.pagosapp.notifications", category: "GenericScheduler")
    
    /// Schedule notifications for any entity type (Payment, Reminder, etc.)
    func scheduleNotifications(
        entityId: UUID,
        title: String,
        dueDate: Date,
        notificationDays: [Int],
        contentBuilder: NotificationContentBuilder
    ) async {
        
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        
        guard settings.authorizationStatus == .authorized else { 
            self.logger.warning("⚠️ Notification authorization not granted for \(entityId)")
            return 
        }

        let calendar = Calendar.current
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        var scheduledCount = 0

        self.logger.info("📅 Scheduling notifications for: \(title) due on \(dateFormatter.string(from: dueDate))")
        self.logger.info("🔔 Notification schedule: \(notificationDays) days before")

        for daysBefore in notificationDays {
            guard let notificationDate = calendar.date(byAdding: .day, value: -daysBefore, to: dueDate) else { 
                self.logger.error("Failed to calculate notification date for \(daysBefore) days before")
                continue 
            }

            if daysBefore == 0 {
                // Schedule notifications for same day: morning and afternoon
                for timeOfDay in TimeOfDay.allCases {
                    let success = await self.scheduleNotification(
                        calendar: calendar,
                        notificationDate: notificationDate,
                        now: now,
                        entityId: entityId,
                        title: title,
                        daysBefore: daysBefore,
                        timeOfDay: timeOfDay,
                        contentBuilder: contentBuilder
                    )
                    
                    if success {
                        scheduledCount += 1
                    }
                }
            } else {
                // Schedule notification for days before (at 9 AM)
                let success = await self.scheduleNotification(
                    calendar: calendar,
                    notificationDate: notificationDate,
                    now: now,
                    entityId: entityId,
                    title: title,
                    daysBefore: daysBefore,
                    timeOfDay: .morning,
                    contentBuilder: contentBuilder
                )
                
                if success {
                    scheduledCount += 1
                }
            }
        }
        
        self.logger.info("📊 Total notifications scheduled: \(scheduledCount) for \(title)")
    }
    
    private func scheduleNotification(
        calendar: Calendar,
        notificationDate: Date,
        now: Date,
        entityId: UUID,
        title: String,
        daysBefore: Int,
        timeOfDay: TimeOfDay,
        contentBuilder: NotificationContentBuilder
    ) async -> Bool {
        
        var comp = calendar.dateComponents([.year, .month, .day], from: notificationDate)
        comp.hour = timeOfDay.hour
        comp.minute = 0
        comp.second = 0
        
        guard let triggerDate = calendar.date(from: comp) else {
            self.logger.error("Failed to create trigger date for \(daysBefore) days before (\(timeOfDay.suffix))")
            return false
        }
        
        guard triggerDate > now else {
            self.logger.info("Skipping past notification time: \(triggerDate)")
            return false
        }
        
        let identifier = contentBuilder.createIdentifier(
            entityId: entityId,
            daysUntilDue: daysBefore,
            timeOfDay: daysBefore == 0 ? timeOfDay : nil
        )
        
        let content = contentBuilder.buildContent(
            daysUntilDue: daysBefore,
            title: title,
            timeOfDay: daysBefore == 0 ? timeOfDay : nil
        )
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: comp, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            self.logger.info("✅ Scheduled \(daysBefore) days before notification (\(timeOfDay.suffix)) for: \(title)")
            return true
        } catch {
            self.logger.error("❌ Failed to schedule \(daysBefore) days before notification (\(timeOfDay.suffix)): \(error.localizedDescription)")
            return false
        }
    }
}