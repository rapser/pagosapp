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
    var oneMonthBefore: Bool
    var twoWeeksBefore: Bool
    var oneWeekBefore: Bool
    
    /// Initialize with default settings (only standard notifications)
    init(
        oneMonthBefore: Bool = false,
        twoWeeksBefore: Bool = false,
        oneWeekBefore: Bool = false
    ) {
        self.oneMonthBefore = oneMonthBefore
        self.twoWeeksBefore = twoWeeksBefore
        self.oneWeekBefore = oneWeekBefore
    }
    
    /// Check if any advanced notifications are enabled
    var hasAdvancedNotifications: Bool {
        oneMonthBefore || twoWeeksBefore || oneWeekBefore
    }
    
    /// Get all notification days (from most distant to closest)
    var allNotificationDays: [Int] {
        var days: [Int] = []
        
        // Advanced notifications (optional)
        if oneMonthBefore { days.append(30) }
        if twoWeeksBefore { days.append(14) }
        if oneWeekBefore { days.append(7) }
        
        // Standard notifications (always enabled) - like payments: 3, 2, 1, 0 days
        days.append(contentsOf: [3, 2, 1, 0])
        
        return days.sorted(by: >) // Descending order: 30, 14, 7, 3, 2, 1, 0
    }
    
    /// Get recommended settings based on reminder type
    static func recommended(for type: ReminderType) -> NotificationSettings {
        switch type {
        case .cardRenewal, .documents, .taxes, .membership, .subscription, .pension:
            // Important types: 1 month before, 2 weeks before + standard (3, 2, 1, 0 days)
            return NotificationSettings(oneMonthBefore: true, twoWeeksBefore: true, oneWeekBefore: false)
            
        case .savings, .deposit, .maintenance, .insurance, .health, .rent, .warranty, .certification, .other:
            // Simple types: 1 week before + standard (3, 2, 1, 0 days)
            return NotificationSettings(oneMonthBefore: false, twoWeeksBefore: false, oneWeekBefore: true)
        }
    }
}
