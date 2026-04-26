//
//  DeleteReminderUseCase.swift
//  pagosApp
//
//  Use case for deleting a reminder (and cancelling its notifications).
//  Clean Architecture - Domain Layer
//

import Foundation

@MainActor
final class DeleteReminderUseCase {
    private let repository: ReminderRepositoryProtocol

    init(repository: ReminderRepositoryProtocol) {
        self.repository = repository
    }

    func execute(id: UUID) async -> Result<Void, ReminderError> {
        await repository.delete(id: id)
    }
}
