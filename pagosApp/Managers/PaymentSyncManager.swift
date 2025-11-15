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

    /// Full sync: Upload local payments and download remote payments
    func performFullSync(modelContext: ModelContext) async {
        guard !isSyncing else {
            logger.warning("⚠️ Sync already in progress")
            return
        }

        isSyncing = true
        defer { isSyncing = false }

        logger.info("Starting full sync...")

        do {
            // 1. Get all local payments
            let descriptor = FetchDescriptor<Payment>()
            let localPayments = try modelContext.fetch(descriptor)
            logger.info("Found \(localPayments.count) local payments")

            // 2. Upload all local payments to server
            if !localPayments.isEmpty {
                try await syncService.syncAllLocalPayments(localPayments)
                logger.info("✅ Uploaded \(localPayments.count) payments to server")
            }

            // 3. Fetch all remote payments
            let remoteDTOs = try await syncService.fetchAllPayments()
            logger.info("Fetched \(remoteDTOs.count) payments from server")

            // 4. Merge remote payments into local database
            await mergeRemotePayments(remoteDTOs, into: modelContext)

            // 5. Update last sync date
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)

            logger.info("✅ Full sync completed successfully")
        } catch {
            logger.error("❌ Full sync failed: \(error.localizedDescription)")
            errorHandler.handle(error)
        }
    }

    /// Merge remote payments into local database (upsert logic)
    private func mergeRemotePayments(_ remoteDTOs: [PaymentDTO], into modelContext: ModelContext) async {
        for dto in remoteDTOs {
            // Check if payment already exists locally
            let predicate = #Predicate<Payment> { payment in
                payment.id == dto.id
            }
            let descriptor = FetchDescriptor(predicate: predicate)

            do {
                let existingPayments = try modelContext.fetch(descriptor)

                if let existingPayment = existingPayments.first {
                    // Update existing payment if remote is newer
                    // Since we don't have updatedAt locally, always update from remote
                    if dto.updatedAt != nil {
                        // Update local payment with remote data
                        existingPayment.name = dto.name
                        existingPayment.amount = dto.amount
                        existingPayment.dueDate = dto.dueDate
                        existingPayment.isPaid = dto.isPaid
                        existingPayment.category = PaymentCategory(rawValue: dto.category) ?? .otro
                        logger.info("Updated local payment: \(dto.name)")
                    }
                } else {
                    // Insert new payment from remote
                    let newPayment = dto.toPayment()
                    modelContext.insert(newPayment)
                    logger.info("Inserted new payment from remote: \(dto.name)")
                }
            } catch {
                logger.error("❌ Error merging payment \(dto.id): \(error.localizedDescription)")
            }
        }

        // Save context
        do {
            try modelContext.save()
            logger.info("✅ Local database updated with remote changes")
        } catch {
            logger.error("❌ Failed to save context: \(error.localizedDescription)")
            errorHandler.handle(PaymentError.saveFailed(error))
        }
    }

    /// Auto-sync on app launch or login
    func autoSyncIfNeeded(modelContext: ModelContext) async {
        // Auto-sync if last sync was more than 1 hour ago or never synced
        let shouldSync: Bool
        if let lastSync = lastSyncDate {
            let hoursSinceLastSync = Date().timeIntervalSince(lastSync) / 3600
            shouldSync = hoursSinceLastSync >= 1
        } else {
            shouldSync = true
        }

        if shouldSync {
            logger.info("Auto-sync triggered (last sync: \(self.lastSyncDate?.description ?? "never"))")
            await performFullSync(modelContext: modelContext)
        } else {
            logger.info("Skipping auto-sync (last sync was recent)")
        }
    }
}
