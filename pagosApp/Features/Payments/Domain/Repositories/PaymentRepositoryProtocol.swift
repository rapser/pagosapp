//
//  PaymentRepositoryProtocol.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//

import Foundation

/// Remote calls are `nonisolated` in the implementation; local SwiftData paths are `@MainActor` (see impl).
protocol PaymentRepositoryProtocol: Sendable {
    // Remote operations
    func fetchAllPayments(userId: UUID) async throws -> [PaymentDTO]
    func upsertPayment(userId: UUID, payment: PaymentDTO) async throws
    func upsertPayments(userId: UUID, payments: [PaymentDTO]) async throws
    func deletePayment(paymentId: UUID) async throws
    func deletePayments(paymentIds: [UUID]) async throws

    // Local (SwiftData / main actor)
    @MainActor
    func getAllLocalPayments() async throws -> [Payment]
    @MainActor
    func getLocalPayment(id: UUID) async throws -> Payment?
    @MainActor
    func savePayment(_ payment: Payment) async throws
    @MainActor
    func savePayments(_ payments: [Payment]) async throws
    @MainActor
    func deleteLocalPayment(id: UUID) async throws
    @MainActor
    func deleteLocalPayments(ids: [UUID]) async throws
    @MainActor
    func clearAllLocalPayments() async throws
}
