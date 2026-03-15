//
//  ReminderLocalDTO.swift
//  pagosApp
//
//  SwiftData model for local persistence of reminders.
//  Clean Architecture - Data Layer (Local DTO)
//

import Foundation
import SwiftData

@Model
final class ReminderLocalDTO {
    @Attribute(.unique) var id: UUID
    var reminderTypeRawValue: String
    var title: String
    var reminderDescription: String?  // Optional for migration: old records may not have it
    var dueDate: Date
    var isCompleted: Bool?  // Optional for migration: old records may not have it (treated as false)
    var notificationSettingsData: Data?  // Optional for migration: old records may not have it
    var syncStatusRawValue: String
    var lastSyncedAt: Date?

    init(
        id: UUID, 
        reminderType: ReminderType, 
        title: String, 
        reminderDescription: String? = nil, 
        dueDate: Date, 
        isCompleted: Bool? = false, 
        notificationSettings: NotificationSettings = NotificationSettings(), 
        syncStatus: ReminderSyncStatus = .local, 
        lastSyncedAt: Date? = nil
    ) {
        self.id = id
        self.reminderTypeRawValue = reminderType.rawValue
        self.title = title
        self.reminderDescription = reminderDescription
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.notificationSettingsData = try? JSONEncoder().encode(notificationSettings)
        self.syncStatusRawValue = syncStatus.rawValue
        self.lastSyncedAt = lastSyncedAt
    }

    var reminderType: ReminderType {
        get { ReminderType.from(storedRawValue: reminderTypeRawValue) }
        set { reminderTypeRawValue = newValue.rawValue }
    }

    var notificationSettings: NotificationSettings {
        get { 
            guard let data = notificationSettingsData,
                  let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) else {
                return NotificationSettings() // Default settings for migration
            }
            return settings
        }
        set { 
            notificationSettingsData = try? JSONEncoder().encode(newValue)
        }
    }

    var syncStatus: ReminderSyncStatus {
        get { ReminderSyncStatus(rawValue: syncStatusRawValue) ?? .local }
        set { syncStatusRawValue = newValue.rawValue }
    }
}
