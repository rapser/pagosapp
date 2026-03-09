//
//  UpdateReminderUseCase.swift
//  pagosApp
//
//  Use case for updating an existing reminder.
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

final class UpdateReminderUseCase {
    private let repository: ReminderRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "UpdateReminderUseCase")

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
            syncStatus: newStatus,
            lastSyncedAt: reminder.lastSyncedAt
        )
        return await repository.update(reminder: updated)
    }
}
