//
//  DownloadReminderChangesUseCase.swift
//  pagosApp
//
//  Use case for downloading remote reminders and merging with local.
//  Clean Architecture - Domain Layer
//

import Foundation

@MainActor
final class DownloadReminderChangesUseCase {
    private static let logCategory = "DownloadReminderChangesUseCase"

    private let syncRepository: ReminderSyncRepositoryProtocol
    private let localDataSource: ReminderLocalDataSource
    private let log: DomainLogWriter
    private let keepLocalWhenPendingSyncStatuses: Set<ReminderSyncStatus> = [.local, .modified, .error]

    init(
        syncRepository: ReminderSyncRepositoryProtocol,
        localDataSource: ReminderLocalDataSource,
        log: DomainLogWriter
    ) {
        self.syncRepository = syncRepository
        self.localDataSource = localDataSource
        self.log = log
    }

    func execute() async -> Result<Void, ReminderSyncError> {
        log.info("📥 Downloading remote reminders", category: Self.logCategory)
        do {
            let userId = try await syncRepository.getCurrentUserId()
            let remote = try await syncRepository.downloadReminders(userId: userId)
            log.info("Downloaded \(remote.count) reminders from remote", category: Self.logCategory)
            let local = try await localDataSource.fetchAll()
            for reminder in remote {
                if let existing = local.first(where: { $0.id == reminder.id }) {
                    // Merge policy: server-wins by default, but preserve any local pending changes.
                    if !keepLocalWhenPendingSyncStatuses.contains(existing.syncStatus) {
                        try await localDataSource.save(reminder)
                        log.info("Updated local reminder from remote: \(reminder.title)", category: Self.logCategory)
                    } else {
                        log.info("Skipped updating \(reminder.title) - has local modifications", category: Self.logCategory)
                    }
                } else {
                    try await localDataSource.save(reminder)
                    log.info("Inserted new reminder from remote: \(reminder.title)", category: Self.logCategory)
                }
            }
            log.info("✅ Downloaded and merged \(remote.count) reminders successfully", category: Self.logCategory)
            return .success(())
        } catch let error as ReminderSyncError {
            log.error("❌ Download failed: \(error.errorCode)", category: Self.logCategory)
            return .failure(error)
        } catch {
            log.error("❌ Download failed: \(error.localizedDescription)", category: Self.logCategory)
            return .failure(.downloadFailed(error.localizedDescription))
        }
    }
}
