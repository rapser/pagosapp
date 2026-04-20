//
//  UpdateReminderUseCase.swift
//  pagosApp
//
//  Use case for updating an existing reminder.
//  Clean Architecture - Domain Layer
//

import Foundation

final class UpdateReminderUseCase {
    private let repository: ReminderRepositoryProtocol

    init(repository: ReminderRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ reminder: Reminder) async -> Result<Reminder, ReminderError> {
        let trimmedTitle = reminder.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            return .failure(.invalidTitle)
        }
        let newStatus: ReminderSyncStatus = reminder.syncStatus == .synced ? .modified : reminder.syncStatus
        let updated = Reminder(
            id: reminder.id,
            reminderType: reminder.reminderType,
            title: trimmedTitle,
            description: reminder.description,
            dueDate: reminder.dueDate,
            isCompleted: reminder.isCompleted,
            notificationSettings: reminder.notificationSettings,
            syncStatus: newStatus,
            lastSyncedAt: reminder.lastSyncedAt
        )
        return await repository.update(reminder: updated)
    }
}
