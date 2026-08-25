//
//  NotificationSettings.swift
//  pagosApp
//
//  Notification settings for reminders
//  Clean Architecture - Domain Layer
//

import Foundation

/// Notification settings for a reminder
struct NotificationSettings: Codable, Sendable, Equatable {
    /// Standard notifications (always enabled): 3 days before, 2 days before, 1 day before, same day (9am & afternoon)
    var enabledStandardNotifications: Bool = true
    
    /// Advanced notifications (optional)
    var twoWeeksBefore: Bool
    var oneWeekBefore: Bool

    /// Initialize with default settings (only standard notifications)
    init(
        twoWeeksBefore: Bool = false,
        oneWeekBefore: Bool = false
    ) {
        self.twoWeeksBefore = twoWeeksBefore
        self.oneWeekBefore = oneWeekBefore
    }

    /// Check if any advanced notifications are enabled
    var hasAdvancedNotifications: Bool {
        twoWeeksBefore || oneWeekBefore
    }

    /// Get all notification days (from most distant to closest)
    var allNotificationDays: [Int] {
        var days: [Int] = []

        // Advanced notifications (optional)
        if twoWeeksBefore { days.append(14) }
        if oneWeekBefore { days.append(7) }

        // Standard notifications (always enabled) - like payments: 3, 2, 1, 0 days
        days.append(contentsOf: [3, 2, 1, 0])

        return days.sorted(by: >) // Descending order: 14, 7, 3, 2, 1, 0
    }

    /// Get recommended settings based on reminder type
    /// Advanced notifications (2 weeks / 1 week before) are always disabled by default,
    /// regardless of reminder type - only the standard 3, 2, 1, 0 day set applies out of the box.
    static func recommended(for type: ReminderType) -> NotificationSettings {
        NotificationSettings()
    }
}
