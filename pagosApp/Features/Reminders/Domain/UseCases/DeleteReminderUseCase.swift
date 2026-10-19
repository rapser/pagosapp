//
//  DeleteReminderUseCase.swift
//  pagosApp
//
//  Use case for deleting a reminder (and cancelling its notifications).
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case for deleting a reminder.
/// - Unsynced reminders (`.local`): deleted from SwiftData only — they never reached Supabase.
/// - Otherwise: deleted from Supabase first, then locally. If Supabase is unreachable the reminder
///   is kept as a hidden tombstone (`.pendingDeletion`) so the next sync deletes it remotely
///   instead of downloading it back.
@MainActor
final class DeleteReminderUseCase {
    private static let logCategory = "DeleteReminderUseCase"

    private let repository: ReminderRepositoryProtocol
    private let syncRepository: ReminderSyncRepositoryProtocol
    private let log: DomainLogWriter

    init(
        repository: ReminderRepositoryProtocol,
        syncRepository: ReminderSyncRepositoryProtocol,
        log: DomainLogWriter
    ) {
        self.repository = repository
        self.syncRepository = syncRepository
        self.log = log
    }

    func execute(id: UUID) async -> Result<Void, ReminderError> {
        var reminder: Reminder?
        if case .success(let found) = await repository.getById(id: id) {
            reminder = found
        }

        guard let reminder, reminder.syncStatus != .local else {
            log.info("ℹ️ Reminder is local-only — skipping Supabase delete: \(id)", category: Self.logCategory)
            return await repository.delete(id: id)
        }

        do {
            try await syncRepository.syncDeletion(reminderId: id)
            log.info("✅ Deleted from Supabase: \(id)", category: Self.logCategory)
            return await repository.delete(id: id)
        } catch {
            log.warning(
                "⚠️ Supabase delete failed (offline?): \(error.localizedDescription) — marking for deletion on next sync",
                category: Self.logCategory
            )
            return await repository.markForDeletion(id: id)
        }
    }
}
