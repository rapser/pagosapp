//
//  ReminderRemoteMapper.swift
//  pagosApp
//
//  Maps between ReminderDTO (remote) and Reminder (domain).
//

import Foundation

enum ReminderRemoteMapper {
    static func toDomain(_ dto: ReminderDTO) -> Reminder {
        Reminder(
            id: dto.id,
            reminderType: ReminderType.from(storedRawValue: dto.reminderType),
            title: dto.title,
            dueDate: dto.dueDate,
            syncStatus: .synced,
            lastSyncedAt: dto.updatedAt ?? dto.createdAt
        )
    }

    static func toDomain(_ dtos: [ReminderDTO]) -> [Reminder] {
        dtos.map { toDomain($0) }
    }

    static func toRemoteDTO(_ reminder: Reminder, userId: UUID) -> ReminderDTO {
        ReminderDTO(
            id: reminder.id,
            userId: userId,
            reminderType: reminder.reminderType.rawValue,
            title: reminder.title,
            dueDate: reminder.dueDate,
            createdAt: nil,
            updatedAt: reminder.lastSyncedAt
        )
    }

    static func toRemoteDTO(_ reminders: [Reminder], userId: UUID) -> [ReminderDTO] {
        reminders.map { toRemoteDTO($0, userId: userId) }
    }
}
