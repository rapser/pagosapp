//
//  PaymentLocalDataSource.swift
//  pagosApp
//
//  Protocol for Payment local data source
//  Clean Architecture - Data Layer
//

import Foundation

/// Protocol for local payment data operations (SwiftData)
protocol PaymentLocalDataSource {
    /// Fetch all payments from local storage
    func fetchAll() async throws -> [Payment]

    /// Fetch a single payment by ID
    func fetch(id: UUID) async throws -> Payment?

    /// Save a single payment
    func save(_ payment: Payment) async throws

    /// Save multiple payments
    func saveAll(_ payments: [Payment]) async throws

    /// Delete a single payment
    func delete(_ payment: Payment) async throws

    /// Delete multiple payments
    func deleteAll(_ payments: [Payment]) async throws

    /// Clear all payments
    func clear() async throws
}
