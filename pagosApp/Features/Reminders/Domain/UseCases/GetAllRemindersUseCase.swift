//
//  GetAllRemindersUseCase.swift
//  pagosApp
//
//  Use case for fetching all reminders (e.g. for list, sorted by date).
//  Clean Architecture - Domain Layer
//

import Foundation

final class GetAllRemindersUseCase {
    private let repository: ReminderRepositoryProtocol

    init(repository: ReminderRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async -> Result<[Reminder], ReminderError> {
        await repository.getAll()
    }
}
