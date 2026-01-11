//
//  PaymentRepositoryImpl.swift
//  pagosApp
//
//  Clean implementation of PaymentRepositoryProtocol
//  Clean Architecture - Data Layer
//

import Foundation
import OSLog

/// Clean implementation of PaymentRepository using DataSources and Mappers
final class PaymentRepositoryImpl: PaymentRepositoryProtocol {
    private let remoteDataSource: PaymentRemoteDataSource
    private let localDataSource: PaymentLocalDataSource
    private let remoteDTOMapper: PaymentRemoteDTOMapping
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "PaymentRepositoryImpl")

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
        logger.info("📥 Fetching all payments for user: \(userId)")
        let dtos = try await remoteDataSource.fetchAll(userId: userId)
        logger.info("✅ Fetched \(dtos.count) payments from remote")
        return dtos
    }

    func upsertPayment(userId: UUID, payment: PaymentDTO) async throws {
        logger.info("📤 Upserting payment: \(payment.name)")
        try await remoteDataSource.upsert(payment, userId: userId)
        logger.info("✅ Payment upserted to remote")
    }

    func upsertPayments(userId: UUID, payments: [PaymentDTO]) async throws {
        guard !payments.isEmpty else {
            logger.info("⚠️ No payments to upsert")
            return
        }

        logger.info("📤 Upserting \(payments.count) payments")
        try await remoteDataSource.upsertAll(payments, userId: userId)
        logger.info("✅ \(payments.count) payments upserted to remote")
    }

    func deletePayment(paymentId: UUID) async throws {
        logger.info("🗑️ Deleting payment from remote: \(paymentId)")
        try await remoteDataSource.delete(id: paymentId)
        logger.info("✅ Payment deleted from remote")
    }

    func deletePayments(paymentIds: [UUID]) async throws {
        guard !paymentIds.isEmpty else {
            logger.info("⚠️ No payments to delete")
            return
        }

        logger.info("🗑️ Deleting \(paymentIds.count) payments from remote")
        try await remoteDataSource.deleteAll(ids: paymentIds)
        logger.info("✅ \(paymentIds.count) payments deleted from remote")
    }

    // MARK: - Local Operations (returns Sendable entities)

    func getAllLocalPayments() async throws -> [Payment] {
        logger.debug("📱 Fetching all local payments")
        return try await _getAllLocalPayments()
    }

    func getLocalPayment(id: UUID) async throws -> Payment? {
        logger.debug("📱 Fetching local payment: \(id)")
        return try await _getLocalPayment(id: id)
    }

    func savePayment(_ payment: Payment) async throws {
        logger.debug("💾 Saving payment locally: \(payment.name)")
        try await _savePayment(payment)
    }

    func savePayments(_ payments: [Payment]) async throws {
        logger.debug("💾 Saving \(payments.count) payments locally")
        try await _savePayments(payments)
    }

    func deleteLocalPayment(id: UUID) async throws {
        logger.debug("🗑️ Deleting local payment: \(id)")
        try await _deleteLocalPayment(id: id)
    }

    func deleteLocalPayments(ids: [UUID]) async throws {
        logger.debug("🗑️ Deleting \(ids.count) local payments")
        try await _deleteLocalPayments(ids: ids)
    }

    func clearAllLocalPayments() async throws {
        logger.info("🗑️ Clearing all local payments")
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
        guard let entity = try await localDataSource.fetch(id: id) else {
            logger.warning("⚠️ Payment not found for deletion: \(id)")
            return
        }
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
