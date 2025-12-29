//
//  PaymentSyncRepositoryProtocol.swift
//  pagosApp
//
//  Domain Repository Protocol for Payment Synchronization
//  Clean Architecture - Domain Layer
//

import Foundation

/// Repository protocol for payment synchronization operations
protocol PaymentSyncRepositoryProtocol {
    /// Get current user ID from auth system
    func getCurrentUserId() async throws -> UUID

    /// Upload local payments to remote
    func uploadPayments(_ payments: [PaymentEntity], userId: UUID) async throws

    /// Download payments from remote
    func downloadPayments(userId: UUID) async throws -> [PaymentEntity]

    /// Sync single payment deletion to remote
    func syncDeletion(paymentId: UUID) async throws

    /// Get payments pending synchronization
    func getPendingPayments() async throws -> [PaymentEntity]

    /// Get pending sync count
    func getPendingSyncCount() async throws -> Int

    /// Update sync status for payment
    func updateSyncStatus(paymentId: UUID, status: SyncStatus) async throws
}
