//
//  GenericNotificationScheduler.swift
//  pagosApp
//
//  Generic notification scheduling service to eliminate code duplication.
//  Replaces duplicate logic between payment and reminder notifications.
//

import Foundation
import UserNotifications

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
@MainActor
final class GenericNotificationScheduler: @unchecked Sendable {
    private static let logCategory = "GenericNotificationScheduler"

    private let log: DomainLogWriter

    init(log: DomainLogWriter) {
        self.log = log
    }

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
            log.warning("⚠️ Notification authorization not granted for \(entityId)", category: Self.logCategory)
            return
        }

        let calendar = Calendar.current
        let now = Date()

        for daysBefore in notificationDays {
            guard let notificationDate = calendar.date(byAdding: .day, value: -daysBefore, to: dueDate) else {
                log.error("Failed to calculate notification date for \(daysBefore) days before", category: Self.logCategory)
                continue
            }

            if daysBefore == 0 {
                // Schedule notifications for same day: morning and afternoon
                for timeOfDay in TimeOfDay.allCases {
                    _ = await self.scheduleNotification(
                        calendar: calendar,
                        notificationDate: notificationDate,
                        now: now,
                        entityId: entityId,
                        title: title,
                        daysBefore: daysBefore,
                        timeOfDay: timeOfDay,
                        contentBuilder: contentBuilder
                    )
                }
            } else {
                // Schedule notification for days before (at 9 AM)
                _ = await self.scheduleNotification(
                    calendar: calendar,
                    notificationDate: notificationDate,
                    now: now,
                    entityId: entityId,
                    title: title,
                    daysBefore: daysBefore,
                    timeOfDay: .morning,
                    contentBuilder: contentBuilder
                )
            }
        }
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
            log.error("Failed to create trigger date for \(daysBefore) days before (\(timeOfDay.suffix))", category: Self.logCategory)
            return false
        }
        
        guard triggerDate > now else {
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
            return true
        } catch {
            log.error("❌ Failed to schedule \(daysBefore) days before notification (\(timeOfDay.suffix)): \(error.localizedDescription)", category: Self.logCategory)
            return false
        }
    }
}