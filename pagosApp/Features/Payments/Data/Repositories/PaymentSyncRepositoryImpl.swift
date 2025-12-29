//
//  PaymentSyncRepositoryImpl.swift
//  pagosApp
//
//  Implementation of PaymentSyncRepositoryProtocol
//  Clean Architecture - Data Layer
//

import Foundation
import Supabase
import OSLog

/// Implementation of payment sync repository
final class PaymentSyncRepositoryImpl: PaymentSyncRepositoryProtocol {
    private let remoteDataSource: PaymentRemoteDataSource
    private let localDataSource: PaymentLocalDataSource
    private let supabaseClient: SupabaseClient
    private let mapper: PaymentMapper.Type
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "PaymentSyncRepositoryImpl")

    init(
        remoteDataSource: PaymentRemoteDataSource,
        localDataSource: PaymentLocalDataSource,
        supabaseClient: SupabaseClient,
        mapper: PaymentMapper.Type = PaymentMapper.self
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
        self.supabaseClient = supabaseClient
        self.mapper = mapper
    }

    // MARK: - Auth

    func getCurrentUserId() async throws -> UUID {
        guard let userId = supabaseClient.auth.currentUser?.id else {
            logger.error("❌ No authenticated user")
            throw PaymentSyncError.notAuthenticated
        }
        return userId
    }

    // MARK: - Upload

    func uploadPayments(_ payments: [PaymentEntity], userId: UUID) async throws {
        logger.info("📤 Uploading \(payments.count) payments")

        // Convert entities to DTOs
        let dtos = mapper.toRemoteDTO(from: payments, userId: userId)

        // Upload to remote
        try await remoteDataSource.upsertAll(dtos, userId: userId)

        // Update local sync status
        var updatedPayments: [PaymentEntity] = []
        for payment in payments {
            let updated = PaymentEntity(
                id: payment.id,
                name: payment.name,
                amount: payment.amount,
                currency: payment.currency,
                dueDate: payment.dueDate,
                isPaid: payment.isPaid,
                category: payment.category,
                eventIdentifier: payment.eventIdentifier,
                syncStatus: .synced,
                lastSyncedAt: Date()
            )
            updatedPayments.append(updated)
        }

        // Save updated entities locally
        try await _savePaymentsLocally(updatedPayments)

        logger.info("✅ \(payments.count) payments uploaded and marked as synced")
    }

    // MARK: - Download

    func downloadPayments(userId: UUID) async throws -> [PaymentEntity] {
        logger.info("📥 Downloading payments for user: \(userId)")

        // Fetch from remote
        let dtos = try await remoteDataSource.fetchAll(userId: userId)

        // Convert to domain entities
        let entities = mapper.toDomain(from: dtos)

        logger.info("✅ Downloaded \(entities.count) payments")
        return entities
    }

    // MARK: - Delete

    func syncDeletion(paymentId: UUID) async throws {
        logger.info("🗑️ Syncing deletion of payment: \(paymentId)")
        try await remoteDataSource.delete(id: paymentId)
        logger.info("✅ Payment deletion synced")
    }

    // MARK: - Pending Payments

    func getPendingPayments() async throws -> [PaymentEntity] {
        logger.debug("📊 Getting pending payments")
        let entities = try await _getAllLocalPayments()

        let pending = entities.filter { payment in
            payment.syncStatus == .local ||
            payment.syncStatus == .modified ||
            payment.syncStatus == .error
        }

        logger.debug("✅ Found \(pending.count) pending payments")
        return pending
    }

    func getPendingSyncCount() async throws -> Int {
        let pending = try await getPendingPayments()
        return pending.count
    }

    // MARK: - Update Sync Status

    func updateSyncStatus(paymentId: UUID, status: SyncStatus) async throws {
        logger.debug("🔄 Updating sync status for \(paymentId) to \(status.rawValue)")

        guard let payment = try await _getLocalPayment(id: paymentId) else {
            logger.warning("⚠️ Payment not found: \(paymentId)")
            return
        }

        let updated = PaymentEntity(
            id: payment.id,
            name: payment.name,
            amount: payment.amount,
            currency: payment.currency,
            dueDate: payment.dueDate,
            isPaid: payment.isPaid,
            category: payment.category,
            eventIdentifier: payment.eventIdentifier,
            syncStatus: status,
            lastSyncedAt: status == .synced ? Date() : payment.lastSyncedAt
        )

        try await _savePaymentLocally(updated)
        logger.debug("✅ Sync status updated")
    }

    // MARK: - Private @MainActor helpers

    @MainActor
    private func _getAllLocalPayments() async throws -> [PaymentEntity] {
        return try await localDataSource.fetchAll()
    }

    @MainActor
    private func _getLocalPayment(id: UUID) async throws -> PaymentEntity? {
        return try await localDataSource.fetch(id: id)
    }

    @MainActor
    private func _savePaymentLocally(_ payment: PaymentEntity) async throws {
        try await localDataSource.save(payment)
    }

    @MainActor
    private func _savePaymentsLocally(_ payments: [PaymentEntity]) async throws {
        try await localDataSource.saveAll(payments)
    }
}
