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

            // O(1) lookup instead of O(n) linear search per item
            let localById = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
            let remoteIds = Set(remote.map { $0.id })

            // Merge policy: server-wins unless local has pending changes
            var toSave: [Reminder] = []
            for reminder in remote {
                if let existing = localById[reminder.id] {
                    if keepLocalWhenPendingSyncStatuses.contains(existing.syncStatus) {
                        log.info("Skipped updating \(reminder.title) - has local modifications", category: Self.logCategory)
                    } else {
                        toSave.append(reminder)
                    }
                } else {
                    toSave.append(reminder)
                }
            }

            if !toSave.isEmpty {
                try await localDataSource.saveAll(toSave)
                log.info("Saved \(toSave.count) reminders from remote", category: Self.logCategory)
            }

            // Propagate server-side deletions: remove synced local items absent from the server
            let deletedOnServer = local.filter { $0.syncStatus == .synced && !remoteIds.contains($0.id) }
            for reminder in deletedOnServer {
                try await localDataSource.delete(id: reminder.id)
                log.info("Deleted locally (removed on server): \(reminder.title)", category: Self.logCategory)
            }

            log.info("✅ Sync complete — saved: \(toSave.count), deleted: \(deletedOnServer.count)", category: Self.logCategory)
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
