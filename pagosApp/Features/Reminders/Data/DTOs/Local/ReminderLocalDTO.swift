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
    var dueDate: Date

    init(id: UUID, reminderType: ReminderType, title: String, dueDate: Date) {
        self.id = id
        self.reminderTypeRawValue = reminderType.rawValue
        self.title = title
        self.dueDate = dueDate
    }

    var reminderType: ReminderType {
        get { ReminderType(rawValue: reminderTypeRawValue) ?? .other }
        set { reminderTypeRawValue = newValue.rawValue }
    }
}
