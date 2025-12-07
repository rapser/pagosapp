//
//  PaymentRepository.swift
//  pagosApp
//
//  Created on 7/12/25.
//

import Foundation
import SwiftData
import Supabase
import OSLog

@MainActor
protocol PaymentRepositoryProtocol {
    // Remote operations
    func fetchAllPayments(userId: UUID) async throws -> [PaymentDTO]
    func upsertPayment(userId: UUID, payment: PaymentDTO) async throws
    func upsertPayments(userId: UUID, payments: [PaymentDTO]) async throws
    func deletePayment(paymentId: UUID) async throws
    func deletePayments(paymentIds: [UUID]) async throws
    
    // Local operations
    func getAllLocalPayments() async throws -> [Payment]
    func getLocalPayment(id: UUID) async throws -> Payment?
    func savePayment(_ payment: Payment) async throws
    func savePayments(_ payments: [Payment]) async throws
    func deleteLocalPayment(_ payment: Payment) async throws
    func deleteLocalPayments(_ payments: [Payment]) async throws
    func clearAllLocalPayments() async throws
}

@MainActor
class PaymentRepository: PaymentRepositoryProtocol {
    private let supabaseClient: SupabaseClient
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "PaymentRepository")
    
    init(supabaseClient: SupabaseClient, modelContext: ModelContext) {
        self.supabaseClient = supabaseClient
        self.modelContext = modelContext
    }
    
    // MARK: - Remote Operations
    
    func fetchAllPayments(userId: UUID) async throws -> [PaymentDTO] {
        logger.info("Fetching all payments from Supabase for user: \(userId)")
        
        let response: [PaymentDTO] = try await supabaseClient
            .from("payments")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        logger.info("✅ Fetched \(response.count) payments from Supabase")
        return response
    }
    
    func upsertPayment(userId: UUID, payment: PaymentDTO) async throws {
        logger.info("Upserting payment to Supabase: \(payment.name)")
        
        try await supabaseClient
            .from("payments")
            .upsert(payment)
            .execute()
        
        logger.info("✅ Payment upserted to Supabase")
    }
    
    func upsertPayments(userId: UUID, payments: [PaymentDTO]) async throws {
        guard !payments.isEmpty else {
            logger.info("No payments to upsert")
            return
        }
        
        logger.info("Upserting \(payments.count) payments to Supabase")
        
        try await supabaseClient
            .from("payments")
            .upsert(payments)
            .execute()
        
        logger.info("✅ \(payments.count) payments upserted to Supabase")
    }
    
    func deletePayment(paymentId: UUID) async throws {
        logger.info("Deleting payment from Supabase: \(paymentId)")
        
        try await supabaseClient
            .from("payments")
            .delete()
            .eq("id", value: paymentId.uuidString)
            .execute()
        
        logger.info("✅ Payment deleted from Supabase")
    }
    
    func deletePayments(paymentIds: [UUID]) async throws {
        guard !paymentIds.isEmpty else {
            logger.info("No payments to delete")
            return
        }
        
        logger.info("Deleting \(paymentIds.count) payments from Supabase")
        
        let idStrings = paymentIds.map { $0.uuidString }
        try await supabaseClient
            .from("payments")
            .delete()
            .in("id", values: idStrings)
            .execute()
        
        logger.info("✅ \(paymentIds.count) payments deleted from Supabase")
    }
    
    // MARK: - Local Operations
    
    func getAllLocalPayments() async throws -> [Payment] {
        let descriptor = FetchDescriptor<Payment>(sortBy: [SortDescriptor(\.dueDate, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }
    
    func getLocalPayment(id: UUID) async throws -> Payment? {
        let descriptor = FetchDescriptor<Payment>(predicate: #Predicate { $0.id == id })
        return try modelContext.fetch(descriptor).first
    }
    
    func savePayment(_ payment: Payment) async throws {
        modelContext.insert(payment)
        try modelContext.save()
        logger.info("✅ Payment saved locally: \(payment.name)")
    }
    
    func savePayments(_ payments: [Payment]) async throws {
        payments.forEach { modelContext.insert($0) }
        try modelContext.save()
        logger.info("✅ \(payments.count) payments saved locally")
    }
    
    func deleteLocalPayment(_ payment: Payment) async throws {
        modelContext.delete(payment)
        try modelContext.save()
        logger.info("✅ Payment deleted locally")
    }
    
    func deleteLocalPayments(_ payments: [Payment]) async throws {
        payments.forEach { modelContext.delete($0) }
        try modelContext.save()
        logger.info("✅ \(payments.count) payments deleted locally")
    }
    
    func clearAllLocalPayments() async throws {
        let descriptor = FetchDescriptor<Payment>()
        let allPayments = try modelContext.fetch(descriptor)
        allPayments.forEach { modelContext.delete($0) }
        try modelContext.save()
        logger.info("✅ All local payments cleared")
    }
}
