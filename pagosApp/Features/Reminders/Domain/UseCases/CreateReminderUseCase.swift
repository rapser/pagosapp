//
//  CreateReminderUseCase.swift
//  pagosApp
//
//  Use case for creating a new reminder.
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

final class CreateReminderUseCase {
    private let repository: ReminderRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "CreateReminderUseCase")

    init(repository: ReminderRepositoryProtocol) {
        self.repository = repository
    }

    func execute(type: ReminderType, title: String, description: String, dueDate: Date) async -> Result<Reminder, ReminderError> {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            return .failure(.invalidTitle)
        }
        let reminder = Reminder(
            id: UUID(),
            reminderType: type,
            title: trimmedTitle,
            description: (description.trimmingCharacters(in: .whitespacesAndNewlines)),
            dueDate: dueDate,
            syncStatus: .local,
            lastSyncedAt: nil
        )
        return await repository.create(reminder: reminder)
    }
}
