//
//  PaymentSyncRepositoryProtocol.swift
//  pagosApp
//
//  Domain Repository Protocol for Payment Synchronization
//  Clean Architecture - Domain Layer
//

import Foundation

/// Repository protocol for payment synchronization operations
protocol PaymentSyncRepositoryProtocol: Sendable {
    /// Get current user ID from auth system
    func getCurrentUserId() async throws -> UUID

    /// Upload local payments to remote and refresh local state (SwiftData on main actor)
    @MainActor
    func uploadPayments(_ payments: [Payment], userId: UUID) async throws

    /// Download payments from remote
    func downloadPayments(userId: UUID) async throws -> [Payment]

    /// Sync single payment deletion to remote
    func syncDeletion(paymentId: UUID) async throws

    @MainActor
    func getPendingPayments() async throws -> [Payment]

    @MainActor
    func getPendingSyncCount() async throws -> Int

    @MainActor
    func updateSyncStatus(paymentId: UUID, status: SyncStatus) async throws
}
