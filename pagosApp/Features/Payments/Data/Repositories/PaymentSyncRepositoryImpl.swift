//
//  PaymentSyncRepositoryImpl.swift
//  pagosApp
//
//  Implementation of PaymentSyncRepositoryProtocol
//  Clean Architecture - Data Layer
//

import Foundation
import Supabase

/// Remote operations are `nonisolated`; SwiftData paths are `@MainActor`.
final class PaymentSyncRepositoryImpl: PaymentSyncRepositoryProtocol, @unchecked Sendable {
    private nonisolated let remoteDataSource: any PaymentRemoteDataSource
    private nonisolated let supabaseClient: SupabaseClient
    private nonisolated let mapper: PaymentMapper.Type
    private let localDataSource: any PaymentLocalDataSource

    init(
        remoteDataSource: any PaymentRemoteDataSource,
        localDataSource: any PaymentLocalDataSource,
        supabaseClient: SupabaseClient,
        mapper: PaymentMapper.Type = PaymentMapper.self
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
        self.supabaseClient = supabaseClient
        self.mapper = mapper
    }

    // MARK: - Auth

    nonisolated func getCurrentUserId() async throws -> UUID {
        guard let userId = supabaseClient.auth.currentUser?.id else {
            throw PaymentSyncError.notAuthenticated
        }
        return userId
    }

    // MARK: - Upload (remote + local)

    @MainActor
    func uploadPayments(_ payments: [Payment], userId: UUID) async throws {
        let dtos = mapper.toRemoteDTO(from: payments, userId: userId)
        try await remoteDataSource.upsertAll(dtos, userId: userId)

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
        try await localDataSource.saveAll(updatedPayments)
    }

    // MARK: - Download

    nonisolated func downloadPayments(userId: UUID) async throws -> [Payment] {
        let dtos = try await remoteDataSource.fetchAll(userId: userId)
        return mapper.toDomain(from: dtos)
    }

    nonisolated func syncDeletion(paymentId: UUID) async throws {
        try await remoteDataSource.delete(id: paymentId)
    }

    // MARK: - Local queries

    @MainActor
    func getPendingPayments() async throws -> [Payment] {
        let entities = try await localDataSource.fetchAll()
        return entities.filter { payment in
            payment.syncStatus == .local ||
            payment.syncStatus == .modified ||
            payment.syncStatus == .error
        }
    }

    @MainActor
    func getPendingSyncCount() async throws -> Int {
        let pending = try await getPendingPayments()
        return pending.count
    }

    @MainActor
    func updateSyncStatus(paymentId: UUID, status: SyncStatus) async throws {
        guard let payment = try await localDataSource.fetch(id: paymentId) else { return }
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
        try await localDataSource.save(updated)
    }
}
