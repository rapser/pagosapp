//
//  PaymentRepositoryImpl.swift
//  pagosApp
//
//  Clean implementation of PaymentRepository using DataSources and Mappers
//  Clean Architecture - Data Layer
//

import Foundation

/// Supabase (remote) and SwiftData (local) share one façade; remote paths are `nonisolated` for Swift 6, local paths `@MainActor`.
final class PaymentRepositoryImpl: PaymentRepositoryProtocol, @unchecked Sendable {
    private nonisolated let remoteDataSource: any PaymentRemoteDataSource
    private let localDataSource: any PaymentLocalDataSource

    init(
        remoteDataSource: any PaymentRemoteDataSource,
        localDataSource: any PaymentLocalDataSource
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
    }

    // MARK: - Remote Operations (nonisolated — Supabase client is used asynchronously)

    nonisolated func fetchAllPayments(userId: UUID) async throws -> [PaymentDTO] {
        try await remoteDataSource.fetchAll(userId: userId)
    }

    nonisolated func upsertPayment(userId: UUID, payment: PaymentDTO) async throws {
        try await remoteDataSource.upsert(payment, userId: userId)
    }

    nonisolated func upsertPayments(userId: UUID, payments: [PaymentDTO]) async throws {
        guard !payments.isEmpty else { return }
        try await remoteDataSource.upsertAll(payments, userId: userId)
    }

    nonisolated func deletePayment(paymentId: UUID) async throws {
        try await remoteDataSource.delete(id: paymentId)
    }

    nonisolated func deletePayments(paymentIds: [UUID]) async throws {
        guard !paymentIds.isEmpty else { return }
        try await remoteDataSource.deleteAll(ids: paymentIds)
    }

    // MARK: - Local (SwiftData on main actor)

    @MainActor
    func getAllLocalPayments() async throws -> [Payment] {
        try await localDataSource.fetchAll()
    }

    @MainActor
    func getLocalPayment(id: UUID) async throws -> Payment? {
        try await localDataSource.fetch(id: id)
    }

    @MainActor
    func savePayment(_ payment: Payment) async throws {
        try await localDataSource.save(payment)
    }

    @MainActor
    func savePayments(_ payments: [Payment]) async throws {
        try await localDataSource.saveAll(payments)
    }

    @MainActor
    func deleteLocalPayment(id: UUID) async throws {
        guard let entity = try await localDataSource.fetch(id: id) else { return }
        try await localDataSource.delete(entity)
    }

    @MainActor
    func deleteLocalPayments(ids: [UUID]) async throws {
        let allModels = try await localDataSource.fetchAll()
        let modelsToDelete = allModels.filter { ids.contains($0.id) }
        try await localDataSource.deleteAll(modelsToDelete)
    }

    @MainActor
    func clearAllLocalPayments() async throws {
        try await localDataSource.clear()
    }
}
