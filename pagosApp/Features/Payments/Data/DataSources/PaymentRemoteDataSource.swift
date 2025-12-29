//
//  PaymentRemoteDataSource.swift
//  pagosApp
//
//  Protocol for Payment remote data source
//  Clean Architecture - Data Layer
//

import Foundation

/// Protocol for remote payment data operations
protocol PaymentRemoteDataSource {
    /// Fetch all payments for a user
    func fetchAll(userId: UUID) async throws -> [PaymentDTO]

    /// Fetch payments with date filters
    func fetchFiltered(userId: UUID, from: Date?, to: Date?) async throws -> [PaymentDTO]

    /// Upsert (insert or update) a single payment
    func upsert(_ payment: PaymentDTO, userId: UUID) async throws

    /// Upsert multiple payments
    func upsertAll(_ payments: [PaymentDTO], userId: UUID) async throws

    /// Delete a single payment
    func delete(id: UUID) async throws

    /// Delete multiple payments
    func deleteAll(ids: [UUID]) async throws
}
