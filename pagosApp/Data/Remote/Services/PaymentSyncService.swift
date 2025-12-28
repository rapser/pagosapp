//
//  PaymentSyncService.swift
//  pagosApp
//
//  Service for syncing payments with Supabase backend
//

import Foundation

/// Protocol for payment synchronization
/// Now uses Repository Pattern for better separation of concerns
protocol PaymentSyncService {
    func syncPayment(_ payment: Payment, userId: UUID) async throws
    func syncDeletePayment(_ paymentId: UUID) async throws
    func syncDeletePayments(_ paymentIds: [UUID]) async throws
    func fetchAllPayments(userId: UUID) async throws -> [PaymentDTO]
    func syncAllLocalPayments(_ payments: [Payment], userId: UUID) async throws
}
