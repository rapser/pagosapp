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
final class ReminderSyncCoordinator {
    private let syncRemindersUseCase: SyncRemindersUseCase
    private let getPendingSyncCountUseCase: GetPendingReminderSyncCountUseCase
    private let syncRepository: ReminderSyncRepositoryProtocol
    private let localDataSource: ReminderLocalDataSource
    private let rescheduleNotificationsUseCase: RescheduleReminderNotificationsUseCase
    private let log: DomainLogWriter

    private static let logCategory = "ReminderSyncCoordinator"

    var isSyncing = false
    var lastSyncDate: Date?
    var pendingSyncCount = 0
    var syncError: Error?

    private let lastSyncKey = "lastReminderSyncDate"

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
        self.lastSyncDate = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
    }

    func performSync() async throws {
        guard !isSyncing else {
            log.warning("⚠️ Reminder sync already in progress", category: Self.logCategory)
            return
        }
        isSyncing = true
        syncError = nil
        defer { isSyncing = false }

        func shouldRetry(_ error: ReminderSyncError) -> Bool {
            switch error {
            case .notAuthenticated:
                return false
            case .uploadFailed, .downloadFailed, .unknown:
                return true
            }
        }

        log.info("🔄 Starting reminder synchronization", category: Self.logCategory)

        for attempt in 1...SyncRetryPolicy.maxAttempts {
            let result = await syncRemindersUseCase.execute()

            switch result {
            case .success:
                lastSyncDate = Date()
                UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)
                syncError = nil
                await updatePendingSyncCount()
                await rescheduleAllReminderNotifications()
                log.info("✅ Reminder synchronization completed successfully", category: Self.logCategory)
                return

            case .failure(let error):
                log.error("❌ Reminder synchronization failed: \(String(describing: error))", category: Self.logCategory)
                syncError = error

                let isLastAttempt = attempt == SyncRetryPolicy.maxAttempts
                if !isLastAttempt, shouldRetry(error) {
                    await SyncRetryPolicy.sleepBeforeRetry(forAttempt: attempt)
                    continue
                }
                throw error
            }
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

    func updatePendingSyncCount() async {
        let count = await getPendingSyncCountUseCase.execute()
        pendingSyncCount = count
        log.info("📊 Pending reminder sync count updated: \(count)", category: Self.logCategory)
    }

    func clearLocalDatabase(force: Bool = false) async -> Bool {
        log.info("Clearing local reminders (force: \(force))", category: Self.logCategory)
        guard force || pendingSyncCount == 0 else {
            log.warning("⚠️ Cannot clear reminders: there are unsynchronized reminders", category: Self.logCategory)
            return false
        }
        do {
            let all = try await localDataSource.fetchAll()
            for reminder in all {
                try await localDataSource.delete(id: reminder.id)
            }
            pendingSyncCount = 0
            lastSyncDate = nil
            UserDefaults.standard.removeObject(forKey: lastSyncKey)
            log.info("✅ Local reminders cleared successfully", category: Self.logCategory)
            return true
        } catch {
            log.error("❌ Failed to clear reminders: \(error.localizedDescription)", category: Self.logCategory)
            return false
        }
    }
}

extension ReminderSyncCoordinator: ReminderSyncCoordinating {}
