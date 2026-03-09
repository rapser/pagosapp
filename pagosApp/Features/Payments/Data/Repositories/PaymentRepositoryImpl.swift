//
//  PaymentRepositoryImpl.swift
//  pagosApp
//
//  Clean implementation of PaymentRepositoryProtocol
//  Clean Architecture - Data Layer
//

import Foundation

/// Clean implementation of PaymentRepository using DataSources and Mappers
final class PaymentRepositoryImpl: PaymentRepositoryProtocol {
    private let remoteDataSource: PaymentRemoteDataSource
    private let localDataSource: PaymentLocalDataSource
    private let remoteDTOMapper: PaymentRemoteDTOMapping

    init(
        remoteDataSource: PaymentRemoteDataSource,
        localDataSource: PaymentLocalDataSource,
        remoteDTOMapper: PaymentRemoteDTOMapping
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
        self.remoteDTOMapper = remoteDTOMapper
    }

    // MARK: - Remote Operations

    func fetchAllPayments(userId: UUID) async throws -> [PaymentDTO] {
        return try await remoteDataSource.fetchAll(userId: userId)
    }

    func upsertPayment(userId: UUID, payment: PaymentDTO) async throws {
        try await remoteDataSource.upsert(payment, userId: userId)
    }

    func upsertPayments(userId: UUID, payments: [PaymentDTO]) async throws {
        guard !payments.isEmpty else { return }
        try await remoteDataSource.upsertAll(payments, userId: userId)
    }

    func deletePayment(paymentId: UUID) async throws {
        try await remoteDataSource.delete(id: paymentId)
    }

    func deletePayments(paymentIds: [UUID]) async throws {
        guard !paymentIds.isEmpty else { return }
        try await remoteDataSource.deleteAll(ids: paymentIds)
    }

    // MARK: - Local Operations (returns Sendable entities)

    func getAllLocalPayments() async throws -> [Payment] {
        return try await _getAllLocalPayments()
    }

    func getLocalPayment(id: UUID) async throws -> Payment? {
        return try await _getLocalPayment(id: id)
    }

    func savePayment(_ payment: Payment) async throws {
        try await _savePayment(payment)
    }

    func savePayments(_ payments: [Payment]) async throws {
        try await _savePayments(payments)
    }

    func deleteLocalPayment(id: UUID) async throws {
        try await _deleteLocalPayment(id: id)
    }

    func deleteLocalPayments(ids: [UUID]) async throws {
        try await _deleteLocalPayments(ids: ids)
    }

    func clearAllLocalPayments() async throws {
        try await _clearAllLocalPayments()
    }

    // MARK: - Private @MainActor methods for SwiftData operations

    @MainActor
    private func _getAllLocalPayments() async throws -> [Payment] {
        return try await localDataSource.fetchAll()
    }

    @MainActor
    private func _getLocalPayment(id: UUID) async throws -> Payment? {
        return try await localDataSource.fetch(id: id)
    }

    @MainActor
    private func _savePayment(_ payment: Payment) async throws {
        try await localDataSource.save(payment)
    }

    @MainActor
    private func _savePayments(_ payments: [Payment]) async throws {
        try await localDataSource.saveAll(payments)
    }

    @MainActor
    private func _deleteLocalPayment(id: UUID) async throws {
        guard let entity = try await localDataSource.fetch(id: id) else { return }
        try await localDataSource.delete(entity)
    }

    @MainActor
    private func _deleteLocalPayments(ids: [UUID]) async throws {
        let allModels = try await localDataSource.fetchAll()
        let modelsToDelete = allModels.filter { ids.contains($0.id) }
        try await localDataSource.deleteAll(modelsToDelete)
    }

    @MainActor
    private func _clearAllLocalPayments() async throws {
        try await localDataSource.clear()
    }
}
