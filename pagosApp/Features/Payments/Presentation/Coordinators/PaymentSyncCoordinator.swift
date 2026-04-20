//
//  PaymentSyncCoordinator.swift
//  pagosApp
//
//  Lightweight coordinator for payment synchronization
//  Delegates all logic to Use Cases
//  Clean Architecture - Presentation/Coordination Layer
//

import Foundation
import Observation

/// Lightweight coordinator for payment synchronization
/// Maintains @Observable state for UI and delegates to Use Cases
@MainActor
@Observable
final class PaymentSyncCoordinator {
    // MARK: - Dependencies (Use Cases)

    private let syncPaymentsUseCase: SyncPaymentsUseCase
    private let getPendingSyncCountUseCase: GetPendingSyncCountUseCase
    private let uploadLocalChangesUseCase: UploadLocalChangesUseCase
    private let downloadRemoteChangesUseCase: DownloadRemoteChangesUseCase
    private let paymentRepository: PaymentRepositoryProtocol
    private let syncRepository: PaymentSyncRepositoryProtocol
    private let eventBus: EventBus

    // MARK: - Observable State (for UI)

    var isSyncing = false
    var lastSyncDate: Date?
    var pendingSyncCount = 0
    var syncError: Error?

    private let lastSyncKey = "lastPaymentSyncDate"
    private let minimumSyncTriggerInterval: TimeInterval = 10
    private var lastSyncTriggerDate: Date?

    // MARK: - Initialization

    init(
        syncPaymentsUseCase: SyncPaymentsUseCase,
        getPendingSyncCountUseCase: GetPendingSyncCountUseCase,
        uploadLocalChangesUseCase: UploadLocalChangesUseCase,
        downloadRemoteChangesUseCase: DownloadRemoteChangesUseCase,
        paymentRepository: PaymentRepositoryProtocol,
        syncRepository: PaymentSyncRepositoryProtocol,
        eventBus: EventBus
    ) {
        self.syncPaymentsUseCase = syncPaymentsUseCase
        self.getPendingSyncCountUseCase = getPendingSyncCountUseCase
        self.uploadLocalChangesUseCase = uploadLocalChangesUseCase
        self.downloadRemoteChangesUseCase = downloadRemoteChangesUseCase
        self.paymentRepository = paymentRepository
        self.syncRepository = syncRepository
        self.eventBus = eventBus

        self.lastSyncDate = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
    }

    // MARK: - Sync Operations (Delegate to Use Cases)

    private func shouldRetry(_ error: PaymentSyncError) -> Bool {
        switch error {
        case .notAuthenticated, .sessionExpired, .conflictError:
            return false
        case .networkError, .uploadFailed, .downloadFailed:
            return true
        case .unknown:
            return true
        }
    }

    private func shouldThrottleSyncTrigger() -> Bool {
        guard let lastSyncTriggerDate else { return false }
        return Date().timeIntervalSince(lastSyncTriggerDate) < minimumSyncTriggerInterval
    }

    /// Perform full synchronization (upload + download)
    func performSync() async throws {
        guard !isSyncing else { return }
        guard !shouldThrottleSyncTrigger() else { return }

        isSyncing = true
        lastSyncTriggerDate = Date()
        syncError = nil
        defer { isSyncing = false }

        for attempt in 1...SyncRetryPolicy.maxAttempts {
            let result = await syncPaymentsUseCase.execute()

            switch result {
            case .success:
                lastSyncDate = Date()
                UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)
                syncError = nil
                await updatePendingSyncCount()
                eventBus.publish(PaymentsSyncedEvent(syncedCount: 0))
                return

            case .failure(let syncError):
                self.syncError = syncError

                let isLastAttempt = attempt == SyncRetryPolicy.maxAttempts
                if !isLastAttempt, shouldRetry(syncError) {
                    await SyncRetryPolicy.sleepBeforeRetry(forAttempt: attempt)
                    continue
                }

                let error = NSError(
                    domain: "PaymentSyncCoordinator",
                    code: 503,
                    userInfo: [
                        NSLocalizedDescriptionKey: L10n.Sync.cannotSync,
                        NSLocalizedRecoverySuggestionErrorKey: L10n.Sync.recoverySuggestion
                    ]
                )
                throw error
            }
        }
    }

    /// Perform initial sync if local database is empty
    func performInitialSyncIfNeeded(isAuthenticated: Bool) async {
        guard isAuthenticated else { return }
        do {
            let allPayments = try await paymentRepository.getAllLocalPayments()
            guard allPayments.isEmpty else { return }
            try await performSync()
        } catch {}
    }

    func updatePendingSyncCount() async {
        pendingSyncCount = await getPendingSyncCountUseCase.execute()
    }

    /// Check if there are pending payments to sync
    func hasPendingSyncPayments() async -> Bool {
        let count = await getPendingSyncCountUseCase.execute()
        return count > 0
    }

    // MARK: - Database Management

    /// Clear all local payments
    /// - Parameter force: If true, clears even if there are pending syncs
    /// - Returns: True if cleared successfully
    @discardableResult
    func clearLocalDatabase(force: Bool = false) async -> Bool {
        if !force {
            let hasPending = await hasPendingSyncPayments()
            if hasPending { return false }
        }
        do {
            try await paymentRepository.clearAllLocalPayments()
            pendingSyncCount = 0
            lastSyncDate = nil
            UserDefaults.standard.removeObject(forKey: lastSyncKey)
            eventBus.publish(PaymentsSyncedEvent(syncedCount: 0))
            return true
        } catch {
            return false
        }
    }
}
