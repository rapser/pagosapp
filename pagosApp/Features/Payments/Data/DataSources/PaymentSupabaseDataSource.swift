//
//  PaymentSupabaseDataSource.swift
//  pagosApp
//
//  Supabase implementation of PaymentRemoteDataSource
//  Clean Architecture - Data Layer
//

import Foundation
import Supabase

/// Supabase implementation for payment remote operations
final class PaymentSupabaseDataSource: PaymentRemoteDataSource {
    private let client: SupabaseClient
    private let tableName = "payments"

    init(client: SupabaseClient) {
        self.client = client
    }

    // MARK: - Fetch Operations

    func fetchAll(userId: UUID) async throws -> [PaymentDTO] {
        let response: [PaymentDTO] = try await client
            .from(tableName)
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        return response
    }

    func fetchFiltered(userId: UUID, from: Date?, to: Date?) async throws -> [PaymentDTO] {
        var query = client
            .from(tableName)
            .select()
            .eq("user_id", value: userId.uuidString)

        if let from = from {
            query = query.gte("due_date", value: from)
        }

        if let to = to {
            query = query.lte("due_date", value: to)
        }

        return try await query.execute().value
    }

    // MARK: - Upsert Operations

    func upsert(_ payment: PaymentDTO, userId: UUID) async throws {
        try await client
            .from(tableName)
            .upsert(payment)
            .execute()
    }

    func upsertAll(_ payments: [PaymentDTO], userId: UUID) async throws {
        guard !payments.isEmpty else { return }
        try await client
            .from(tableName)
            .upsert(payments)
            .execute()
    }

    // MARK: - Delete Operations

    func delete(id: UUID) async throws {
        try await client
            .from(tableName)
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func deleteAll(ids: [UUID]) async throws {
        guard !ids.isEmpty else { return }
        let uuidStrings = ids.map { $0.uuidString }
        try await client
            .from(tableName)
            .delete()
            .in("id", values: uuidStrings)
            .execute()
    }
}
