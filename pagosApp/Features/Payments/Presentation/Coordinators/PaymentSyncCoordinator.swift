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
final class PaymentSyncCoordinator: BaseSyncCoordinator<PaymentSyncError> {
    // MARK: - Dependencies (Use Cases)

    private let syncPaymentsUseCase: SyncPaymentsUseCase
    private let getPendingSyncCountUseCase: GetPendingSyncCountUseCase
    private let uploadLocalChangesUseCase: UploadLocalChangesUseCase
    private let downloadRemoteChangesUseCase: DownloadRemoteChangesUseCase
    private let paymentRepository: PaymentRepositoryProtocol
    private let syncRepository: PaymentSyncRepositoryProtocol
    private let eventBus: EventBus

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
        super.init(lastSyncKey: "lastPaymentSyncDate")
    }

    // MARK: - Sync Operations (Delegate to Use Cases)

    override func shouldRetry(after error: PaymentSyncError) -> Bool {
        switch error {
        case .notAuthenticated, .sessionExpired, .conflictError:
            return false
        case .networkError, .uploadFailed, .downloadFailed:
            return true
        case .unknown:
            return true
        }
    }

    override func executeSyncAttempt() async -> Result<Void, PaymentSyncError> {
        await syncPaymentsUseCase.execute()
    }

    override func terminalError(for error: PaymentSyncError) -> Error {
        _ = error
        return NSError(
            domain: "PaymentSyncCoordinator",
            code: 503,
            userInfo: [
                NSLocalizedDescriptionKey: L10n.Sync.cannotSync,
                NSLocalizedRecoverySuggestionErrorKey: L10n.Sync.recoverySuggestion
            ]
        )
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

    override func fetchPendingSyncCount() async -> Int {
        await getPendingSyncCountUseCase.execute()
    }

    /// Check if there are pending payments to sync
    func hasPendingSyncPayments() async -> Bool {
        let count = await getPendingSyncCountUseCase.execute()
        return count > 0
    }

    // MARK: - Database Management

    override func performLocalDatabaseClear() async -> Bool {
        do {
            try await paymentRepository.clearAllLocalPayments()
            return true
        } catch {
            return false
        }
    }

    override func didCompleteSyncSuccessfully() async {
        eventBus.publish(PaymentsSyncedEvent(syncedCount: 0))
    }

    override func didClearLocalDatabase() async {
        eventBus.publish(PaymentsSyncedEvent(syncedCount: 0))
    }
}

extension PaymentSyncCoordinator: PaymentSyncCoordinating {}
