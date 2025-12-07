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

protocol PaymentRepositoryProtocol {
    // Remote operations (no @MainActor - can run on background)
    func fetchAllPayments(userId: UUID) async throws -> [PaymentDTO]
    func upsertPayment(userId: UUID, payment: PaymentDTO) async throws
    func upsertPayments(userId: UUID, payments: [PaymentDTO]) async throws
    func deletePayment(paymentId: UUID) async throws
    func deletePayments(paymentIds: [UUID]) async throws
    
    // Local operations (@MainActor - SwiftData requires main thread)
    @MainActor func getAllLocalPayments() async throws -> [Payment]
    @MainActor func getLocalPayment(id: UUID) async throws -> Payment?
    @MainActor func savePayment(_ payment: Payment) async throws
    @MainActor func savePayments(_ payments: [Payment]) async throws
    @MainActor func deleteLocalPayment(_ payment: Payment) async throws
    @MainActor func deleteLocalPayments(_ payments: [Payment]) async throws
    @MainActor func clearAllLocalPayments() async throws
}

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
    /// @MainActor required because SwiftDataStorageAdapter requires main actor
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
    
    // MARK: - Local Operations (delegates to localStorage adapter)
    
    @MainActor
    func getAllLocalPayments() async throws -> [Payment] {
        logger.debug("📱 Fetching all local payments")
        return try await localStorage.fetchAll()
    }
    
    @MainActor
    func getLocalPayment(id: UUID) async throws -> Payment? {
        logger.debug("📱 Fetching local payment: \(id)")
        // Fetch all and filter in memory (for simple queries this is efficient enough)
        let allPayments = try await localStorage.fetchAll()
        return allPayments.first(where: { $0.id == id })
    }
    
    @MainActor
    func savePayment(_ payment: Payment) async throws {
        logger.debug("💾 Saving payment locally: \(payment.name)")
        try await localStorage.save(payment)
    }
    
    @MainActor
    func savePayments(_ payments: [Payment]) async throws {
        logger.debug("💾 Saving \(payments.count) payments locally")
        try await localStorage.saveAll(payments)
    }
    
    @MainActor
    func deleteLocalPayment(_ payment: Payment) async throws {
        logger.debug("🗑️ Deleting local payment: \(payment.name)")
        try await localStorage.delete(payment)
    }
    
    @MainActor
    func deleteLocalPayments(_ payments: [Payment]) async throws {
        logger.debug("🗑️ Deleting \(payments.count) local payments")
        try await localStorage.deleteAll(payments)
    }
    
    @MainActor
    func clearAllLocalPayments() async throws {
        logger.info("🗑️ Clearing all local payments")
        try await localStorage.clear()
    }
}
