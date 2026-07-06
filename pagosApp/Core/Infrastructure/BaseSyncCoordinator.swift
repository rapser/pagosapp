//
//  BaseSyncCoordinator.swift
//  pagosApp
//
//  Shared template-method style base for sync coordinators.
//

import Foundation
import Observation

@MainActor
@Observable
class BaseSyncCoordinator<Failure: Error> {
    var isSyncing = false
    var lastSyncDate: Date?
    var pendingSyncCount = 0
    var syncError: Error?

    private let lastSyncKey: String

    init(lastSyncKey: String) {
        self.lastSyncKey = lastSyncKey
        self.lastSyncDate = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
    }

    func performSync() async throws {
        guard !isSyncing else {
            didSkipSyncBecauseInProgress()
            return
        }

        isSyncing = true
        syncError = nil
        didStartSync()
        defer { isSyncing = false }

        for attempt in 1...SyncRetryPolicy.maxAttempts {
            let result = await executeSyncAttempt()

            switch result {
            case .success:
                markSyncSucceeded()
                await updatePendingSyncCount()
                await didCompleteSyncSuccessfully()
                return

            case .failure(let error):
                syncError = error
                didReceiveSyncFailure(error)

                let isLastAttempt = attempt == SyncRetryPolicy.maxAttempts
                if !isLastAttempt, shouldRetry(after: error) {
                    await sleepBeforeRetry(forAttempt: attempt)
                    continue
                }

                throw terminalError(for: error)
            }
        }
    }

    func updatePendingSyncCount() async {
        pendingSyncCount = await fetchPendingSyncCount()
    }

    @discardableResult
    func clearLocalDatabase(force: Bool = false) async -> Bool {
        if !force {
            let hasPending = await hasPendingSyncItems()
            if hasPending {
                return false
            }
        }

        let didClear = await performLocalDatabaseClear()
        guard didClear else { return false }

        pendingSyncCount = 0
        syncError = nil
        resetStoredSyncState()
        await didClearLocalDatabase()
        return true
    }

    func hasPendingSyncItems() async -> Bool {
        await fetchPendingSyncCount() > 0
    }

    func sleepBeforeRetry(forAttempt attempt: Int) async {
        await SyncRetryPolicy.sleepBeforeRetry(forAttempt: attempt)
    }

    func executeSyncAttempt() async -> Result<Void, Failure> {
        fatalError("Subclasses must override executeSyncAttempt()")
    }

    func shouldRetry(after error: Failure) -> Bool {
        _ = error
        return false
    }

    func terminalError(for error: Failure) -> Error {
        error
    }

    func fetchPendingSyncCount() async -> Int {
        0
    }

    func performLocalDatabaseClear() async -> Bool {
        false
    }

    func didStartSync() {}

    func didSkipSyncBecauseInProgress() {}

    func didReceiveSyncFailure(_ error: Failure) {
        _ = error
    }

    func didCompleteSyncSuccessfully() async {}

    func didClearLocalDatabase() async {}

    private func markSyncSucceeded() {
        let now = Date()
        lastSyncDate = now
        UserDefaults.standard.set(now, forKey: lastSyncKey)
        syncError = nil
    }

    private func resetStoredSyncState() {
        lastSyncDate = nil
        UserDefaults.standard.removeObject(forKey: lastSyncKey)
    }
}
