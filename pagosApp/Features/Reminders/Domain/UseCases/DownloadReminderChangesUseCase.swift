//
//  DownloadReminderChangesUseCase.swift
//  pagosApp
//
//  Use case for downloading remote reminders and merging with local.
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

final class DownloadReminderChangesUseCase {
    private let syncRepository: ReminderSyncRepositoryProtocol
    private let localDataSource: ReminderLocalDataSource
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "DownloadReminderChangesUseCase")
    private let keepLocalWhenPendingSyncStatuses: Set<ReminderSyncStatus> = [.local, .modified, .error]

    init(syncRepository: ReminderSyncRepositoryProtocol, localDataSource: ReminderLocalDataSource) {
        self.syncRepository = syncRepository
        self.localDataSource = localDataSource
    }

    func execute() async -> Result<Void, ReminderSyncError> {
        logger.info("📥 Downloading remote reminders")
        do {
            let userId = try await syncRepository.getCurrentUserId()
            let remote = try await syncRepository.downloadReminders(userId: userId)
            logger.info("Downloaded \(remote.count) reminders from remote")
            let local = try await localDataSource.fetchAll()
            for reminder in remote {
                if let existing = local.first(where: { $0.id == reminder.id }) {
                    // Merge policy: server-wins by default, but preserve any local pending changes.
                    if !keepLocalWhenPendingSyncStatuses.contains(existing.syncStatus) {
                        try await localDataSource.save(reminder)
                        logger.info("Updated local reminder from remote: \(reminder.title)")
                    } else {
                        logger.info("Skipped updating \(reminder.title) - has local modifications")
                    }
                } else {
                    try await localDataSource.save(reminder)
                    logger.info("Inserted new reminder from remote: \(reminder.title)")
                }
            }
            logger.info("✅ Downloaded and merged \(remote.count) reminders successfully")
            return .success(())
        } catch let error as ReminderSyncError {
            logger.error("❌ Download failed: \(error.errorCode)")
            return .failure(error)
        } catch {
            logger.error("❌ Download failed: \(error.localizedDescription)")
            return .failure(.downloadFailed(error.localizedDescription))
        }
    }
}
