//
//  PaymentRepositoryProtocol.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

protocol PaymentRepositoryProtocol {
    // Remote operations (no @MainActor - can run on background)
    func fetchAllPayments(userId: UUID) async throws -> [PaymentDTO]
    func upsertPayment(userId: UUID, payment: PaymentDTO) async throws
    func upsertPayments(userId: UUID, payments: [PaymentDTO]) async throws
    func deletePayment(paymentId: UUID) async throws
    func deletePayments(paymentIds: [UUID]) async throws

    // Local operations (returns Sendable entities, @MainActor internally for SwiftData)
    func getAllLocalPayments() async throws -> [Payment]
    func getLocalPayment(id: UUID) async throws -> Payment?
    func savePayment(_ payment: Payment) async throws
    func savePayments(_ payments: [Payment]) async throws
    func deleteLocalPayment(id: UUID) async throws
    func deleteLocalPayments(ids: [UUID]) async throws
    func clearAllLocalPayments() async throws
}
