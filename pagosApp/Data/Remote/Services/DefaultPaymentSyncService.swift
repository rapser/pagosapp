//
//  DefaultPaymentSyncService.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation
import Supabase
import OSLog

/// Implementation using Repository Pattern
final class DefaultPaymentSyncService: PaymentSyncService {
    private let repository: PaymentRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "PaymentSync")

    init(repository: PaymentRepositoryProtocol) {
        self.repository = repository
    }

    /// Sync a single payment (upsert: insert or update)
    func syncPayment(_ payment: Payment, userId: UUID) async throws {
        let dto = payment.toDTO(userId: userId)

        do {
            logger.info("Syncing payment: \(payment.name) (ID: \(payment.id))")
            
            try await repository.upsertPayment(userId: userId, payment: dto)
            
            logger.info("✅ Payment synced successfully: \(payment.name)")
        } catch {
            logger.error("❌ Failed to sync payment: \(error.localizedDescription)")
            throw PaymentSyncError.syncFailed(error)
        }
    }

    /// Sync deletion of a payment
    func syncDeletePayment(_ paymentId: UUID) async throws {
        do {
            logger.info("Deleting payment from server: \(paymentId)")
            
            try await repository.deletePayment(paymentId: paymentId)
            
            logger.info("✅ Payment deleted from server: \(paymentId)")
        } catch {
            logger.error("❌ Failed to delete payment from server: \(error.localizedDescription)")
            throw PaymentSyncError.deleteFailed(error)
        }
    }
    
    /// Sync deletion of multiple payments
    func syncDeletePayments(_ paymentIds: [UUID]) async throws {
        guard !paymentIds.isEmpty else {
            logger.info("No payments to delete")
            return
        }
        
        do {
            logger.info("Deleting \(paymentIds.count) payments from server")
            
            try await repository.deletePayments(paymentIds: paymentIds)
            
            logger.info("✅ Deleted \(paymentIds.count) payments from server")
        } catch {
            logger.error("❌ Failed to delete payments from server: \(error.localizedDescription)")
            throw PaymentSyncError.deleteFailed(error)
        }
    }

    /// Fetch all payments from server
    func fetchAllPayments(userId: UUID) async throws -> [PaymentDTO] {
        do {
            logger.info("Fetching all payments from server for user: \(userId)")
            
            let response = try await repository.fetchAllPayments(userId: userId)
            
            logger.info("✅ Fetched \(response.count) payments from server")
            return response
        } catch {
            logger.error("❌ Failed to fetch payments: \(error.localizedDescription)")
            throw PaymentSyncError.fetchFailed(error)
        }
    }

    /// Sync all local payments to server (bulk upsert)
    func syncAllLocalPayments(_ payments: [Payment], userId: UUID) async throws {
        let dtos = payments.map { $0.toDTO(userId: userId) }

        guard !dtos.isEmpty else {
            logger.info("No payments to sync")
            return
        }

        do {
            logger.info("Syncing \(dtos.count) payments to server")
            
            try await repository.upsertPayments(userId: userId, payments: dtos)
            
            logger.info("✅ Synced \(dtos.count) payments successfully")
        } catch {
            logger.error("❌ Failed to sync payments: \(error.localizedDescription)")
            throw PaymentSyncError.syncFailed(error)
        }
    }
}