//
//  PaymentSyncManager.swift
//  pagosApp
//
//  Manages synchronization between local SwiftData and Supabase backend
//  Modern iOS 18+ using @Observable macro
//

import Foundation
import SwiftData
import Observation
import OSLog

/// Manages synchronization between local SwiftData and Supabase backend
/// Refactored to support Dependency Injection (no more Singleton)
@MainActor
@Observable
final class PaymentSyncManager {
    private var syncService: PaymentSyncService?
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "PaymentSyncManager")
    private let errorHandler: ErrorHandler
    private weak var authRepository: AuthRepository?

    var isSyncing = false
    var lastSyncDate: Date?
    var pendingSyncCount = 0
    var syncError: Error?

    private let lastSyncKey = "lastPaymentSyncDate"

    // MARK: - Initialization

    init(errorHandler: ErrorHandler, authRepository: AuthRepository? = nil) {
        self.errorHandler = errorHandler
        self.authRepository = authRepository
        self.lastSyncDate = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
    }

    /// Set auth repository after initialization (for DI circular dependency resolution)
    func setAuthRepository(_ repository: AuthRepository) {
        self.authRepository = repository
    }
    
    /// Initialize with modelContext (call once at app startup)
    func configure(with modelContext: ModelContext) {
        guard syncService == nil else { return } // Only configure once
        let repository = PaymentRepository(supabaseClient: supabaseClient, modelContext: modelContext)
        self.syncService = DefaultPaymentSyncService(repository: repository)
        logger.info("✅ PaymentSyncManager configured with repository")
    }
    
    private func ensureConfigured() {
        guard syncService != nil else {
            logger.error("❌ PaymentSyncManager not configured! Call configure(with:) first")
            fatalError("PaymentSyncManager must be configured with modelContext before use")
        }
    }
    
    /// Get current user ID from Supabase auth
    private func getCurrentUserId() throws -> UUID {
        guard let userId = supabaseClient.auth.currentUser?.id else {
            throw PaymentSyncError.notAuthenticated
        }
        return userId
    }

    /// Sync a single payment to server
    func syncPayment(_ payment: Payment, userId: UUID) async {
        ensureConfigured()
        guard let service = syncService else { return }
        
        do {
            try await service.syncPayment(payment, userId: userId)
            logger.info("✅ Payment synced: \(payment.name)")
        } catch {
            logger.error("❌ Failed to sync payment: \(error.localizedDescription)")
            errorHandler.handle(error)
        }
    }

    /// Sync payment deletion to server
    func syncDeletePayment(_ paymentId: UUID) async {
        ensureConfigured()
        guard let service = syncService else { return }
        
        do {
            try await service.syncDeletePayment(paymentId)
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
            logger.info("📊 Pending sync count updated: \(self.pendingSyncCount) payments")
            
            // Log details for debugging
            if pendingSyncCount > 0 {
                logger.info("⚠️ Payments pending sync breakdown:")
                for payment in pendingPayments {
                    logger.info("  - \(payment.name): status=\(payment.syncStatus.rawValue)")
                }
            }
        } catch {
            logger.error("❌ Failed to update pending sync count: \(error.localizedDescription)")
            // Don't reset to 0 - keep the last known value to avoid hiding pending items
            // Only log the error for debugging
        }
    }

    /// Perform initial sync after login if local database is empty
    func performInitialSyncIfNeeded(modelContext: ModelContext, isAuthenticated: Bool) async {
        guard isAuthenticated else { return }

        do {
            let allPayments = try fetchAllPayments(from: modelContext)

            // Only sync if database is completely empty
            guard allPayments.isEmpty else {
                logger.info("Local database has \(allPayments.count) payments. Skipping initial sync.")
                return
            }

            logger.info("Local database is empty. Performing initial sync...")
            try await performManualSync(modelContext: modelContext, isAuthenticated: isAuthenticated)

            // Post notification to refresh views
            NotificationCenter.default.post(name: NSNotification.Name("PaymentsDidSync"), object: nil)
        } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == 256 {
            // Handle "The file couldn't be opened" error
            logger.warning("⚠️ Database file access error during initial sync: \(error.localizedDescription)")
            logger.info("Will retry sync on next manual sync attempt")
        } catch {
            logger.error("Initial sync failed: \(error.localizedDescription)")
        }
    }

    /// Check if there are pending payments to sync before logout
    /// Returns true if there are unsynchronized payments
    func hasPendingSyncPayments(modelContext: ModelContext) -> Bool {
        do {
            let allPayments = try fetchAllPayments(from: modelContext)
            let pendingPayments = filterPendingPayments(allPayments)
            return !pendingPayments.isEmpty
        } catch {
            logger.error("❌ Failed to check pending sync: \(error.localizedDescription)")
            return false // Safe default: allow logout if we can't check
        }
    }

    /// Clear all local payments and pending deletions from database (used on logout)
    /// This ONLY clears SwiftData locally - NEVER touches Supabase server
    /// This method is robust and doesn't depend on ModelContext being available
    /// - Parameter modelContext: ModelContext to use for deletion
    /// - Parameter force: If true, clears even if there are pending syncs (default: false)
    /// - Returns: True if cleared successfully, false if there are pending syncs and force is false
    @discardableResult
    func clearLocalDatabase(modelContext: ModelContext? = nil, force: Bool = false) -> Bool {
        logger.info("Clearing local database on logout (force: \(force))")

        // Check for pending syncs if not forcing
        if !force, let context = modelContext {
            if hasPendingSyncPayments(modelContext: context) {
                logger.warning("⚠️ Cannot clear database: there are unsynchronized payments")
                return false
            }
        }

        // Try to clear via ModelContext if available
        if let context = modelContext {
            do {
                let allPayments = try fetchAllPayments(from: context)

                for payment in allPayments {
                    context.delete(payment)
                }

                try context.save()
                logger.info("✅ Local SwiftData cleared via ModelContext (Supabase untouched)")
            } catch {
                logger.warning("⚠️ Failed to clear via ModelContext, falling back to file deletion: \(error.localizedDescription)")
                // Fall back to file deletion if ModelContext fails
                forceDeleteDatabaseFiles()
            }
        } else {
            // No ModelContext available, use file deletion
            forceDeleteDatabaseFiles()
        }

        // Reset sync state regardless of method used
        pendingSyncCount = 0
        lastSyncDate = nil
        UserDefaults.standard.removeObject(forKey: lastSyncKey)

        // Post notification to refresh views
        NotificationCenter.default.post(name: NSNotification.Name("PaymentsDidSync"), object: nil)

        logger.info("✅ Local SwiftData cleared successfully (Supabase data preserved)")
        return true
    }

    /// Force delete database files when ModelContext is not available or corrupted
    /// This ONLY deletes local SwiftData files - Supabase data remains completely untouched
    private func forceDeleteDatabaseFiles() {
        if let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let storeURL = appSupportURL.appendingPathComponent("default.store")

            // Delete all database files (ignore errors)
            let _ = try? FileManager.default.removeItem(at: storeURL)
            let _ = try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
            let _ = try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))

            logger.info("✅ Local SwiftData files deleted successfully (Supabase untouched)")
        } else {
            logger.error("❌ Could not find application support directory")
        }
    }

    /// Force database reset - deletes the entire database file and recreates it
    /// Use this as a last resort when the database is corrupted
    /// This ONLY affects local SwiftData files - Supabase data remains untouched
    func forceDatabaseReset() -> Bool {
        logger.warning("🔄 Forcing database reset due to corruption")

        if let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let storeURL = appSupportURL.appendingPathComponent("default.store")

            // Delete all database files (ignore errors)
            let _ = try? FileManager.default.removeItem(at: storeURL)
            let _ = try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
            let _ = try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))

            // Reset sync state
            pendingSyncCount = 0
            lastSyncDate = nil
            UserDefaults.standard.removeObject(forKey: lastSyncKey)

            logger.info("✅ Local SwiftData files deleted successfully. App restart required. (Supabase data preserved)")
            return true
        } else {
            logger.error("❌ Could not find application support directory")
            return false
        }
    }

    /// Manual sync: Upload pending local changes and download remote changes
    /// - Parameter isAuthenticated: Whether user is logged in locally
    /// Note: In offline-first apps, we try to sync even if local state shows not authenticated
    /// The ensureValidSession() call will determine if sync can actually proceed
    func performManualSync(modelContext: ModelContext, isAuthenticated: Bool) async throws {
        // Don't block sync based on local auth state - let ensureValidSession() decide
        // This allows syncing when token expired but user is still "logged in" locally
        if !isAuthenticated {
            logger.info("ℹ️ Local auth state is false, but will attempt sync anyway (offline-first mode)")
        }

        guard !isSyncing else {
            logger.warning("⚠️ Sync already in progress")
            return
        }

        isSyncing = true
        // Clear previous errors at the start
        syncError = nil
        defer { isSyncing = false }

        logger.info("🔄 Starting manual sync...")

        // IMPORTANT: Verify and refresh session before syncing (offline-first approach)
        do {
            if let authRepo = authRepository {
                try await authRepo.ensureValidSession()
                logger.info("✅ Session verified and valid - proceeding with sync")
            } else {
                logger.warning("⚠️ AuthRepository not set, skipping session verification")
            }
        } catch {
            // Session validation failed - likely offline or expired token
            // This is OK for offline-first apps - just can't sync right now
            logger.warning("⚠️ No se puede sincronizar: \(error.localizedDescription)")
            logger.info("💡 Puedes seguir trabajando localmente. La sincronización se realizará cuando tengas conexión.")

            let sessionError = NSError(
                domain: "PaymentSyncManager",
                code: 503, // Service Unavailable (más apropiado que 401 Unauthorized)
                userInfo: [
                    NSLocalizedDescriptionKey: "No se puede sincronizar en este momento",
                    NSLocalizedRecoverySuggestionErrorKey: "Verifica tu conexión a internet. Puedes seguir trabajando localmente y sincronizar más tarde."
                ]
            )
            syncError = sessionError
            throw sessionError
        }

        do {
            // 1. Upload local changes (only payments that need syncing)
            try await uploadLocalChanges(modelContext: modelContext)

            // 2. Download remote changes
            try await downloadRemoteChanges(modelContext: modelContext)

            // 3. Update counters and state
            updatePendingSyncCount(modelContext: modelContext)
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)

            // 4. Clear any previous errors since sync completed successfully
            syncError = nil

            // 5. Notify that sync completed so views can refresh
            NotificationCenter.default.post(name: NSNotification.Name("PaymentsDidSync"), object: nil)

            logger.info("✅ Manual sync completed successfully")
        } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == 256 {
            // Handle "The file couldn't be opened" error specifically
            logger.error("❌ Manual sync failed due to database access error: \(error.localizedDescription)")
            logger.warning("⚠️ Database file may be corrupted or inaccessible. Try restarting the app.")
            syncError = PaymentSyncError.networkError
            throw PaymentSyncError.networkError
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
        
        do {
            try modelContext.save()
        } catch {
            logger.error("❌ Failed to save 'syncing' status: \(error.localizedDescription)")
            // Continue anyway - we'll try to sync even if we can't persist the status
        }

        // Upload to server
        do {
            ensureConfigured()
            guard let service = syncService else { return }
            let userId = try getCurrentUserId()
            
            try await service.syncAllLocalPayments(paymentsToSync, userId: userId)

            // Mark as synced
            for payment in paymentsToSync {
                payment.syncStatus = .synced
                payment.lastSyncedAt = Date()
            }
            
            do {
                try modelContext.save()
                logger.info("✅ Uploaded \(paymentsToSync.count) payments successfully")
            } catch {
                logger.error("❌ Failed to save 'synced' status: \(error.localizedDescription)")
                // This is critical - if we can't save synced status, revert to previous state
                for payment in paymentsToSync {
                    payment.syncStatus = .modified
                }
                throw error
            }
        } catch {
            // Mark as error
            logger.error("❌ Upload failed, marking payments as error: \(error.localizedDescription)")
            for payment in paymentsToSync {
                payment.syncStatus = .error
            }
            
            do {
                try modelContext.save()
            } catch let saveError {
                logger.error("❌ CRITICAL: Failed to save 'error' status: \(saveError.localizedDescription)")
                // If we can't even save error status, database might be corrupted
            }
            
            throw error
        }
    }

    /// Download and merge remote changes
    private func downloadRemoteChanges(modelContext: ModelContext) async throws {
        ensureConfigured()
        guard let service = syncService else { return }
        let userId = try getCurrentUserId()
        
        let remoteDTOs = try await service.fetchAllPayments(userId: userId)
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
                    existingPayment.currency = Currency(rawValue: dto.currency) ?? .pen
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
}
