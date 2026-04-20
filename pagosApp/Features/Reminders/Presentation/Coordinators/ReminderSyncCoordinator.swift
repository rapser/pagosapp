//
//  ReminderSyncCoordinator.swift
//  pagosApp
//
//  Lightweight coordinator for reminder synchronization with Supabase.
//  Clean Architecture - Presentation/Coordination Layer
//

import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class ReminderSyncCoordinator {
    private let syncRemindersUseCase: SyncRemindersUseCase
    private let getPendingSyncCountUseCase: GetPendingReminderSyncCountUseCase
    private let syncRepository: ReminderSyncRepositoryProtocol
    private let localDataSource: ReminderLocalDataSource
    private let rescheduleNotificationsUseCase: RescheduleReminderNotificationsUseCase
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "ReminderSyncCoordinator")

    var isSyncing = false
    var lastSyncDate: Date?
    var pendingSyncCount = 0
    var syncError: Error?

    private let lastSyncKey = "lastReminderSyncDate"
    private let minimumSyncTriggerInterval: TimeInterval = 10
    private var lastSyncTriggerDate: Date?

    init(
        syncRemindersUseCase: SyncRemindersUseCase,
        getPendingSyncCountUseCase: GetPendingReminderSyncCountUseCase,
        syncRepository: ReminderSyncRepositoryProtocol,
        localDataSource: ReminderLocalDataSource,
        rescheduleNotificationsUseCase: RescheduleReminderNotificationsUseCase
    ) {
        self.syncRemindersUseCase = syncRemindersUseCase
        self.getPendingSyncCountUseCase = getPendingSyncCountUseCase
        self.syncRepository = syncRepository
        self.localDataSource = localDataSource
        self.rescheduleNotificationsUseCase = rescheduleNotificationsUseCase
        self.lastSyncDate = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
    }

    func performSync() async throws {
        guard !isSyncing else {
            logger.warning("⚠️ Reminder sync already in progress")
            return
        }
        if let lastSyncTriggerDate,
           Date().timeIntervalSince(lastSyncTriggerDate) < minimumSyncTriggerInterval {
            logger.info("⏭️ Reminder sync skipped due to cooldown")
            return
        }
        isSyncing = true
        lastSyncTriggerDate = Date()
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

        logger.info("🔄 Starting reminder synchronization")

        for attempt in 1...SyncRetryPolicy.maxAttempts {
            let result = await syncRemindersUseCase.execute()

            switch result {
            case .success:
                lastSyncDate = Date()
                UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)
                syncError = nil
                await updatePendingSyncCount()
                await rescheduleAllReminderNotifications()
                logger.info("✅ Reminder synchronization completed successfully")
                return

            case .failure(let error):
                logger.error("❌ Reminder synchronization failed: \(error)")
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
            logger.info("🔔 Rescheduled notifications for \(reminders.count) reminders after sync")
        } catch {
            logger.error("⚠️ Failed to reschedule reminder notifications after sync: \(error.localizedDescription)")
        }
    }

    func updatePendingSyncCount() async {
        let count = await getPendingSyncCountUseCase.execute()
        pendingSyncCount = count
        logger.info("📊 Pending reminder sync count updated: \(count)")
    }

    func clearLocalDatabase(force: Bool = false) async -> Bool {
        logger.info("Clearing local reminders (force: \(force))")
        guard force || pendingSyncCount == 0 else {
            logger.warning("⚠️ Cannot clear reminders: there are unsynchronized reminders")
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
            logger.info("✅ Local reminders cleared successfully")
            return true
        } catch {
            logger.error("❌ Failed to clear reminders: \(error.localizedDescription)")
            return false
        }
    }
}
