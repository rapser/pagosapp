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
            dueDate: dto.dueDate
        )
    }

    static func toDTO(_ reminder: Reminder) -> ReminderLocalDTO {
        ReminderLocalDTO(
            id: reminder.id,
            reminderType: reminder.reminderType,
            title: reminder.title,
            dueDate: reminder.dueDate
        )
    }
}
