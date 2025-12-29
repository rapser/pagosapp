//
//  PaymentSyncCoordinator.swift
//  pagosApp
//
//  Lightweight coordinator for payment synchronization
//  Delegates all logic to Use Cases
//  Clean Architecture - Presentation/Coordination Layer
//

import Foundation
import SwiftData
import Observation
import OSLog

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

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "PaymentSyncCoordinator")

    // MARK: - Observable State (for UI)

    var isSyncing = false
    var lastSyncDate: Date?
    var pendingSyncCount = 0
    var syncError: Error?

    private let lastSyncKey = "lastPaymentSyncDate"

    // MARK: - Initialization

    init(
        syncPaymentsUseCase: SyncPaymentsUseCase,
        getPendingSyncCountUseCase: GetPendingSyncCountUseCase,
        uploadLocalChangesUseCase: UploadLocalChangesUseCase,
        downloadRemoteChangesUseCase: DownloadRemoteChangesUseCase,
        paymentRepository: PaymentRepositoryProtocol,
        syncRepository: PaymentSyncRepositoryProtocol
    ) {
        self.syncPaymentsUseCase = syncPaymentsUseCase
        self.getPendingSyncCountUseCase = getPendingSyncCountUseCase
        self.uploadLocalChangesUseCase = uploadLocalChangesUseCase
        self.downloadRemoteChangesUseCase = downloadRemoteChangesUseCase
        self.paymentRepository = paymentRepository
        self.syncRepository = syncRepository

        self.lastSyncDate = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
    }

    // MARK: - Sync Operations (Delegate to Use Cases)

    /// Perform full synchronization (upload + download)
    func performSync() async throws {
        guard !isSyncing else {
            logger.warning("⚠️ Sync already in progress")
            return
        }

        isSyncing = true
        syncError = nil
        defer { isSyncing = false }

        logger.info("🔄 Starting full synchronization")

        // Delegate to SyncPaymentsUseCase
        let result = await syncPaymentsUseCase.execute()

        switch result {
        case .success:
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)
            syncError = nil

            // Update pending count
            await updatePendingSyncCount()

            // Notify views to refresh
            NotificationCenter.default.post(name: NSNotification.Name("PaymentsDidSync"), object: nil)

            logger.info("✅ Synchronization completed successfully")

        case .failure(let error):
            logger.error("❌ Synchronization failed: \(error.errorCode)")
            syncError = NSError(
                domain: "PaymentSyncCoordinator",
                code: 503,
                userInfo: [
                    NSLocalizedDescriptionKey: "No se puede sincronizar en este momento",
                    NSLocalizedRecoverySuggestionErrorKey: "Verifica tu conexión a internet. Puedes seguir trabajando localmente y sincronizar más tarde."
                ]
            )
            throw syncError!
        }
    }

    /// Perform initial sync if local database is empty
    func performInitialSyncIfNeeded(isAuthenticated: Bool) async {
        guard isAuthenticated else { return }

        do {
            let allPayments = try await paymentRepository.getAllLocalPayments()

            guard allPayments.isEmpty else {
                logger.info("Local database has \(allPayments.count) payments. Skipping initial sync.")
                return
            }

            logger.info("Local database is empty. Performing initial sync...")
            try await performSync()
        } catch {
            logger.error("Initial sync failed: \(error.localizedDescription)")
        }
    }

    /// Update pending sync count
    func updatePendingSyncCount() async {
        let count = await getPendingSyncCountUseCase.execute()
        pendingSyncCount = count
        logger.info("📊 Pending sync count updated: \(count) payments")
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
        logger.info("Clearing local database (force: \(force))")

        // Check for pending syncs if not forcing
        if !force {
            let hasPending = await hasPendingSyncPayments()
            if hasPending {
                logger.warning("⚠️ Cannot clear database: there are unsynchronized payments")
                return false
            }
        }

        do {
            try await paymentRepository.clearAllLocalPayments()

            // Reset sync state
            pendingSyncCount = 0
            lastSyncDate = nil
            UserDefaults.standard.removeObject(forKey: lastSyncKey)

            // Notify views to refresh
            NotificationCenter.default.post(name: NSNotification.Name("PaymentsDidSync"), object: nil)

            logger.info("✅ Local database cleared successfully")
            return true
        } catch {
            logger.error("❌ Failed to clear database: \(error.localizedDescription)")
            return false
        }
    }
}
