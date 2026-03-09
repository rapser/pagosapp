//
//  PaymentSyncRepositoryImpl.swift
//  pagosApp
//
//  Implementation of PaymentSyncRepositoryProtocol
//  Clean Architecture - Data Layer
//

import Foundation
import Supabase

/// Implementation of payment sync repository
final class PaymentSyncRepositoryImpl: PaymentSyncRepositoryProtocol {
    private let remoteDataSource: PaymentRemoteDataSource
    private let localDataSource: PaymentLocalDataSource
    private let supabaseClient: SupabaseClient
    private let mapper: PaymentMapper.Type

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
            throw PaymentSyncError.notAuthenticated
        }
        return userId
    }

    func uploadPayments(_ payments: [Payment], userId: UUID) async throws {
        let dtos = mapper.toRemoteDTO(from: payments, userId: userId)

        // Upload to remote
        try await remoteDataSource.upsertAll(dtos, userId: userId)

        // Update local sync status
        var updatedPayments: [Payment] = []
        for payment in payments {
            let updated = Payment(
                id: payment.id,
                name: payment.name,
                amount: payment.amount,
                currency: payment.currency,
                dueDate: payment.dueDate,
                isPaid: payment.isPaid,
                category: payment.category,
                eventIdentifier: payment.eventIdentifier,
                syncStatus: .synced,
                lastSyncedAt: Date(),
                groupId: payment.groupId
            )
            updatedPayments.append(updated)
        }

        try await _savePaymentsLocally(updatedPayments)
    }

    // MARK: - Download

    func downloadPayments(userId: UUID) async throws -> [Payment] {
        let dtos = try await remoteDataSource.fetchAll(userId: userId)
        return mapper.toDomain(from: dtos)
    }

    func syncDeletion(paymentId: UUID) async throws {
        try await remoteDataSource.delete(id: paymentId)
    }

    func getPendingPayments() async throws -> [Payment] {
        let entities = try await _getAllLocalPayments()
        return entities.filter { payment in
            payment.syncStatus == .local ||
            payment.syncStatus == .modified ||
            payment.syncStatus == .error
        }
    }

    func getPendingSyncCount() async throws -> Int {
        let pending = try await getPendingPayments()
        return pending.count
    }

    // MARK: - Update Sync Status

    func updateSyncStatus(paymentId: UUID, status: SyncStatus) async throws {
        guard let payment = try await _getLocalPayment(id: paymentId) else { return }

        let updated = Payment(
            id: payment.id,
            name: payment.name,
            amount: payment.amount,
            currency: payment.currency,
            dueDate: payment.dueDate,
            isPaid: payment.isPaid,
            category: payment.category,
            eventIdentifier: payment.eventIdentifier,
            syncStatus: status,
            lastSyncedAt: status == .synced ? Date() : payment.lastSyncedAt,
            groupId: payment.groupId
        )

        try await _savePaymentLocally(updated)
    }

    // MARK: - Private @MainActor helpers

    @MainActor
    private func _getAllLocalPayments() async throws -> [Payment] {
        return try await localDataSource.fetchAll()
    }

    @MainActor
    private func _getLocalPayment(id: UUID) async throws -> Payment? {
        return try await localDataSource.fetch(id: id)
    }

    @MainActor
    private func _savePaymentLocally(_ payment: Payment) async throws {
        try await localDataSource.save(payment)
    }

    @MainActor
    private func _savePaymentsLocally(_ payments: [Payment]) async throws {
        try await localDataSource.saveAll(payments)
    }
}
