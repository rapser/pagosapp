//
//  PaymentSyncManager.swift
//  pagosApp
//
//  Manages synchronization between local SwiftData and Supabase backend
//

import Foundation
import SwiftData
import OSLog

@MainActor
class PaymentSyncManager: ObservableObject {
    static let shared = PaymentSyncManager()

    private let syncService: PaymentSyncService
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "PaymentSyncManager")
    private let errorHandler = ErrorHandler.shared

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var pendingSyncCount = 0
    @Published var syncError: Error?

    private let lastSyncKey = "lastPaymentSyncDate"

    init(syncService: PaymentSyncService = SupabasePaymentSyncService(client: supabaseClient)) {
        self.syncService = syncService
        self.lastSyncDate = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
    }

    /// Sync a single payment to server
    func syncPayment(_ payment: Payment) async {
        do {
            try await syncService.syncPayment(payment)
            logger.info("✅ Payment synced: \(payment.name)")
        } catch {
            logger.error("❌ Failed to sync payment: \(error.localizedDescription)")
            errorHandler.handle(error)
        }
    }

    /// Sync payment deletion to server
    func syncDeletePayment(_ paymentId: UUID) async {
        do {
            try await syncService.syncDeletePayment(paymentId)
            logger.info("✅ Payment deletion synced: \(paymentId)")
        } catch {
            logger.error("❌ Failed to sync payment deletion: \(error.localizedDescription)")
            errorHandler.handle(error)
        }
    }

    /// Update count of payments pending synchronization
    func updatePendingSyncCount(modelContext: ModelContext) {
        do {
            let allPayments = try fetchAllPayments(from: modelContext)
            let pendingPayments = filterPendingPayments(allPayments)
            pendingSyncCount = pendingPayments.count
        } catch {
            pendingSyncCount = 0
        }
    }

    /// Manual sync: Upload pending local changes and download remote changes
    /// - Parameter isAuthenticated: Whether user is logged in
    func performManualSync(modelContext: ModelContext, isAuthenticated: Bool) async throws {
        guard isAuthenticated else {
            let error = NSError(
                domain: "PaymentSyncManager",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Debes iniciar sesión para sincronizar"]
            )
            syncError = error
            logger.warning("Sync attempted without authentication")
            throw error
        }

        guard !isSyncing else {
            logger.warning("⚠️ Sync already in progress")
            return
        }

        isSyncing = true
        syncError = nil
        defer { isSyncing = false }

        logger.info("🔄 Starting manual sync...")

        do {
            // 1. Upload local changes (only payments that need syncing)
            try await uploadLocalChanges(modelContext: modelContext)

            // 2. Download remote changes
            try await downloadRemoteChanges(modelContext: modelContext)

            // 3. Update counters and state
            updatePendingSyncCount(modelContext: modelContext)
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)

            logger.info("✅ Manual sync completed successfully")
        } catch {
            logger.error("❌ Manual sync failed: \(error.localizedDescription)")
            syncError = error
            throw error
        }
    }

    // MARK: - Private Helper Methods

    /// Fetch all payments from modelContext
    private func fetchAllPayments(from modelContext: ModelContext) throws -> [Payment] {
        let descriptor = FetchDescriptor<Payment>()
        return try modelContext.fetch(descriptor)
    }

    /// Filter payments that need syncing
    private func filterPendingPayments(_ payments: [Payment]) -> [Payment] {
        return payments.filter { payment in
            payment.syncStatus == .local ||
            payment.syncStatus == .modified ||
            payment.syncStatus == .error
        }
    }

    /// Find existing payment by ID
    private func findPayment(byId id: UUID, in payments: [Payment]) -> Payment? {
        return payments.first { $0.id == id }
    }

    /// Upload only payments that need syncing
    private func uploadLocalChanges(modelContext: ModelContext) async throws {
        let allPayments = try fetchAllPayments(from: modelContext)
        let paymentsToSync = filterPendingPayments(allPayments)

        logger.info("Found \(paymentsToSync.count) payments to upload")

        guard !paymentsToSync.isEmpty else { return }

        // Mark as syncing
        for payment in paymentsToSync {
            payment.syncStatus = .syncing
        }
        try modelContext.save()

        // Upload to server
        do {
            try await syncService.syncAllLocalPayments(paymentsToSync)

            // Mark as synced
            for payment in paymentsToSync {
                payment.syncStatus = .synced
                payment.lastSyncedAt = Date()
            }
            try modelContext.save()

            logger.info("✅ Uploaded \(paymentsToSync.count) payments successfully")
        } catch {
            // Mark as error
            for payment in paymentsToSync {
                payment.syncStatus = .error
            }
            try? modelContext.save()
            throw error
        }
    }

    /// Download and merge remote changes
    private func downloadRemoteChanges(modelContext: ModelContext) async throws {
        let remoteDTOs = try await syncService.fetchAllPayments()
        logger.info("Fetched \(remoteDTOs.count) payments from server")

        try await mergeRemotePayments(remoteDTOs, into: modelContext)
    }

    /// Merge remote payments into local database (upsert logic)
    private func mergeRemotePayments(_ remoteDTOs: [PaymentDTO], into modelContext: ModelContext) async throws {
        // Fetch all local payments once
        let localPayments = try fetchAllPayments(from: modelContext)

        for dto in remoteDTOs {
            // Find existing payment by ID
            if let existingPayment = findPayment(byId: dto.id, in: localPayments) {
                // Only update if not locally modified
                if existingPayment.syncStatus != .modified && existingPayment.syncStatus != .local {
                    // Update local payment with remote data
                    existingPayment.name = dto.name
                    existingPayment.amount = dto.amount
                    existingPayment.dueDate = dto.dueDate
                    existingPayment.isPaid = dto.isPaid
                    existingPayment.category = PaymentCategory(rawValue: dto.category) ?? .otro
                    existingPayment.syncStatus = .synced
                    existingPayment.lastSyncedAt = Date()
                    logger.info("Updated local payment from remote: \(dto.name)")
                } else {
                    logger.info("Skipped updating \(dto.name) - has local modifications")
                }
            } else {
                // Insert new payment from remote
                let newPayment = dto.toPayment()
                newPayment.syncStatus = .synced
                newPayment.lastSyncedAt = Date()
                modelContext.insert(newPayment)
                logger.info("Inserted new payment from remote: \(dto.name)")
            }
        }

        // Save context
        do {
            try modelContext.save()
            logger.info("✅ Local database updated with remote changes")
        } catch {
            logger.error("❌ Failed to save context: \(error.localizedDescription)")
            errorHandler.handle(PaymentError.saveFailed(error))
            throw error
        }
    }

    // MARK: - Deprecated Methods

    /// Deprecated: Use performManualSync instead
    @available(*, deprecated, message: "Use performManualSync for offline-first behavior")
    func performFullSync(modelContext: ModelContext, isAuthenticated: Bool = false) async {
        do {
            try await performManualSync(modelContext: modelContext, isAuthenticated: isAuthenticated)
        } catch {
            logger.error("❌ Full sync failed: \(error.localizedDescription)")
            errorHandler.handle(error)
        }
    }

    /// Auto-sync on app launch or login - DISABLED for offline-first mode
    /// User must manually sync from Settings
    @available(*, deprecated, message: "Auto-sync disabled for offline-first behavior. Use manual sync from Settings.")
    func autoSyncIfNeeded(modelContext: ModelContext) async {
        logger.info("⚠️ Auto-sync is disabled. User must manually sync from Settings.")
        // Update pending count so user knows to sync
        updatePendingSyncCount(modelContext: modelContext)
    }
}
