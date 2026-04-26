//
//  GetPendingReminderSyncCountUseCase.swift
//  pagosApp
//
//  Use case for getting count of reminders pending sync.
//  Clean Architecture - Domain Layer
//

import Foundation

@MainActor
final class GetPendingReminderSyncCountUseCase {
    private let syncRepository: ReminderSyncRepositoryProtocol

    init(syncRepository: ReminderSyncRepositoryProtocol) {
        self.syncRepository = syncRepository
    }

    func execute() async -> Int {
        (try? await syncRepository.getPendingSyncCount()) ?? 0
    }
}
