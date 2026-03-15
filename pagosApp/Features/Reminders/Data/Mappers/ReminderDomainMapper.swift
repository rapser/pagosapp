//
//  ReminderDomainMapper.swift
//  pagosApp
//
//  Maps between ReminderLocalDTO and Reminder (Domain).
//

import Foundation

enum ReminderDomainMapper {
    static func toDomain(_ dto: ReminderLocalDTO) -> Reminder {
        Reminder(
            id: dto.id,
            reminderType: dto.reminderType,
            title: dto.title,
            description: dto.reminderDescription ?? "",
            dueDate: dto.dueDate,
            isCompleted: dto.isCompleted ?? false,
            notificationSettings: dto.notificationSettings,
            syncStatus: dto.syncStatus,
            lastSyncedAt: dto.lastSyncedAt
        )
    }

    static func toDTO(_ reminder: Reminder) -> ReminderLocalDTO {
        ReminderLocalDTO(
            id: reminder.id,
            reminderType: reminder.reminderType,
            title: reminder.title,
            reminderDescription: reminder.description,
            dueDate: reminder.dueDate,
            isCompleted: reminder.isCompleted,
            notificationSettings: reminder.notificationSettings,
            syncStatus: reminder.syncStatus,
            lastSyncedAt: reminder.lastSyncedAt
        )
    }
}
