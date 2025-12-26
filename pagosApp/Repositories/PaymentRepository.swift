//
//  PaymentRepository.swift
//  pagosApp
//
//  Repository using Strategy Pattern with Storage Adapters
//  Can swap between different storage implementations without breaking the app
//

import Foundation
import OSLog
import SwiftData
import Supabase

/// PaymentRepository using Storage Adapters (Strategy Pattern)
/// Can swap remoteStorage (Supabase → Firebase → AWS) and localStorage (SwiftData → SQLite → Realm)
final class PaymentRepository: PaymentRepositoryProtocol {
    private let remoteStorage: any PaymentRemoteStorage
    private let localStorage: any PaymentLocalStorage
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "PaymentRepository")
    
    /// Primary initializer with dependency injection
    init(remoteStorage: any PaymentRemoteStorage, localStorage: any PaymentLocalStorage) {
        self.remoteStorage = remoteStorage
        self.localStorage = localStorage
        logger.info("✅ PaymentRepository initialized with custom storage adapters")
    }
    
    /// Convenience initializer for current setup (Supabase + SwiftData)
    @MainActor
    convenience init(supabaseClient: SupabaseClient, modelContext: ModelContext) {
        let remoteStorage = PaymentSupabaseStorage(client: supabaseClient)
        let localStorage = PaymentSwiftDataStorage(modelContext: modelContext)
        self.init(remoteStorage: remoteStorage, localStorage: localStorage)
    }
    
    // MARK: - Remote Operations (delegates to remoteStorage adapter)
    
    func fetchAllPayments(userId: UUID) async throws -> [PaymentDTO] {
        logger.info("📥 Fetching all payments for user: \(userId)")
        let payments = try await remoteStorage.fetchAll(userId: userId)
        logger.info("✅ Fetched \(payments.count) payments")
        return payments
    }
    
    func upsertPayment(userId: UUID, payment: PaymentDTO) async throws {
        logger.info("📤 Upserting payment: \(payment.name)")
        try await remoteStorage.upsert(payment, userId: userId)
        logger.info("✅ Payment upserted")
    }
    
    func upsertPayments(userId: UUID, payments: [PaymentDTO]) async throws {
        guard !payments.isEmpty else {
            logger.info("⚠️ No payments to upsert")
            return
        }
        
        logger.info("📤 Upserting \(payments.count) payments")
        try await remoteStorage.upsertAll(payments, userId: userId)
        logger.info("✅ \(payments.count) payments upserted")
    }
    
    func deletePayment(paymentId: UUID) async throws {
        logger.info("🗑️ Deleting payment: \(paymentId)")
        try await remoteStorage.delete(id: paymentId)
        logger.info("✅ Payment deleted")
    }
    
    func deletePayments(paymentIds: [UUID]) async throws {
        guard !paymentIds.isEmpty else {
            logger.info("⚠️ No payments to delete")
            return
        }
        
        logger.info("🗑️ Deleting \(paymentIds.count) payments")
        try await remoteStorage.deleteAll(ids: paymentIds)
        logger.info("✅ \(paymentIds.count) payments deleted")
    }
    
    // MARK: - Local Operations (delegates to localStorage adapter, returns Sendable entities)
    
    func getAllLocalPayments() async throws -> [PaymentEntity] {
        logger.debug("📱 Fetching all local payments")
        return try await _getAllLocalPayments()
    }
    
    func getLocalPayment(id: UUID) async throws -> PaymentEntity? {
        logger.debug("📱 Fetching local payment: \(id)")
        return try await _getLocalPayment(id: id)
    }
    
    func savePayment(_ payment: PaymentEntity) async throws {
        logger.debug("💾 Saving payment locally: \(payment.name)")
        try await _savePayment(payment)
    }
    
    func savePayments(_ payments: [PaymentEntity]) async throws {
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
    
    private func _getAllLocalPayments() async throws -> [PaymentEntity] {
        let payments = try await localStorage.fetchAll()
        return payments.toEntities()
    }
    
    private func _getLocalPayment(id: UUID) async throws -> PaymentEntity? {
        let allPayments = try await localStorage.fetchAll()
        return allPayments.first(where: { $0.id == id }).map { PaymentEntity(from: $0) }
    }
    
    @MainActor
    private func _savePayment(_ payment: PaymentEntity) async throws {
        let model = payment.toModel()
        try await localStorage.save(model)
    }
    
    @MainActor
    private func _savePayments(_ payments: [PaymentEntity]) async throws {
        let models = payments.toModels()
        try await localStorage.saveAll(models)
    }
    
    private func _deleteLocalPayment(id: UUID) async throws {
        let allPayments = try await localStorage.fetchAll()
        if let payment = allPayments.first(where: { $0.id == id }) {
            try await localStorage.delete(payment)
        }
    }
    
    private func _deleteLocalPayments(ids: [UUID]) async throws {
        let allPayments = try await localStorage.fetchAll()
        let paymentsToDelete = allPayments.filter { ids.contains($0.id) }
        try await localStorage.deleteAll(paymentsToDelete)
    }
    
    @MainActor
    private func _clearAllLocalPayments() async throws {
        try await localStorage.clear()
    }
}
