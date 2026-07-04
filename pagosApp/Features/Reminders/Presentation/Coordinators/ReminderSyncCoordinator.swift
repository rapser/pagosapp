//
//  ReminderSyncCoordinator.swift
//  pagosApp
//
//  Lightweight coordinator for reminder synchronization with Supabase.
//  Clean Architecture - Presentation/Coordination Layer
//

import Foundation
import Observation

@MainActor
@Observable
final class ReminderSyncCoordinator: BaseSyncCoordinator<ReminderSyncError> {
    private let syncRemindersUseCase: SyncRemindersUseCase
    private let getPendingSyncCountUseCase: GetPendingReminderSyncCountUseCase
    private let syncRepository: ReminderSyncRepositoryProtocol
    private let localDataSource: ReminderLocalDataSource
    private let rescheduleNotificationsUseCase: RescheduleReminderNotificationsUseCase
    private let log: DomainLogWriter

    private static let logCategory = "ReminderSyncCoordinator"

    init(
        syncRemindersUseCase: SyncRemindersUseCase,
        getPendingSyncCountUseCase: GetPendingReminderSyncCountUseCase,
        syncRepository: ReminderSyncRepositoryProtocol,
        localDataSource: ReminderLocalDataSource,
        rescheduleNotificationsUseCase: RescheduleReminderNotificationsUseCase,
        log: DomainLogWriter
    ) {
        self.syncRemindersUseCase = syncRemindersUseCase
        self.getPendingSyncCountUseCase = getPendingSyncCountUseCase
        self.syncRepository = syncRepository
        self.localDataSource = localDataSource
        self.rescheduleNotificationsUseCase = rescheduleNotificationsUseCase
        self.log = log
        super.init(lastSyncKey: "lastReminderSyncDate")
    }

    override func didSkipSyncBecauseInProgress() {
        log.warning("⚠️ Reminder sync already in progress", category: Self.logCategory)
    }

    override func didStartSync() {
        log.info("🔄 Starting reminder synchronization", category: Self.logCategory)
    }

    override func executeSyncAttempt() async -> Result<Void, ReminderSyncError> {
        await syncRemindersUseCase.execute()
    }

    override func shouldRetry(after error: ReminderSyncError) -> Bool {
        switch error {
        case .notAuthenticated:
            return false
        case .uploadFailed, .downloadFailed, .unknown:
            return true
        }
    }

    private func rescheduleAllReminderNotifications() async {
        do {
            let reminders = try await localDataSource.fetchAll()
            rescheduleNotificationsUseCase.rescheduleAll(reminders)
            log.info("🔔 Rescheduled notifications for \(reminders.count) reminders after sync", category: Self.logCategory)
        } catch {
            log.error(
                "⚠️ Failed to reschedule reminder notifications after sync: \(error.localizedDescription)",
                category: Self.logCategory
            )
        }
    }

    override func didReceiveSyncFailure(_ error: ReminderSyncError) {
        log.error("❌ Reminder synchronization failed: \(String(describing: error))", category: Self.logCategory)
    }

    override func didCompleteSyncSuccessfully() async {
        await rescheduleAllReminderNotifications()
        log.info("✅ Reminder synchronization completed successfully", category: Self.logCategory)
    }

    override func fetchPendingSyncCount() async -> Int {
        let count = await getPendingSyncCountUseCase.execute()
        log.info("📊 Pending reminder sync count updated: \(count)", category: Self.logCategory)
        return count
    }

    override func performLocalDatabaseClear() async -> Bool {
        do {
            let all = try await localDataSource.fetchAll()
            for reminder in all {
                try await localDataSource.delete(id: reminder.id)
            }
            log.info("✅ Local reminders cleared successfully", category: Self.logCategory)
            return true
        } catch {
            log.error("❌ Failed to clear reminders: \(error.localizedDescription)", category: Self.logCategory)
            return false
        }
    }
}

extension ReminderSyncCoordinator: ReminderSyncCoordinating {}
