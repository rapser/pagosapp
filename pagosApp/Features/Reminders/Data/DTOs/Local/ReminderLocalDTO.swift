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
    var syncStatusRawValue: String
    var lastSyncedAt: Date?

    init(id: UUID, reminderType: ReminderType, title: String, reminderDescription: String? = nil, dueDate: Date, syncStatus: ReminderSyncStatus = .local, lastSyncedAt: Date? = nil) {
        self.id = id
        self.reminderTypeRawValue = reminderType.rawValue
        self.title = title
        self.reminderDescription = reminderDescription
        self.dueDate = dueDate
        self.syncStatusRawValue = syncStatus.rawValue
        self.lastSyncedAt = lastSyncedAt
    }

    var reminderType: ReminderType {
        get { ReminderType.from(storedRawValue: reminderTypeRawValue) }
        set { reminderTypeRawValue = newValue.rawValue }
    }

    var syncStatus: ReminderSyncStatus {
        get { ReminderSyncStatus(rawValue: syncStatusRawValue) ?? .local }
        set { syncStatusRawValue = newValue.rawValue }
    }
}
