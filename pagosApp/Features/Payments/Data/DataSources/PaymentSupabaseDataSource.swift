//
//  PaymentSupabaseDataSource.swift
//  pagosApp
//
//  Supabase implementation of PaymentRemoteDataSource
//  Clean Architecture - Data Layer
//

import Foundation
import Supabase
import OSLog

/// Supabase implementation for payment remote operations
final class PaymentSupabaseDataSource: PaymentRemoteDataSource {
    private let client: SupabaseClient
    private let tableName = "payments"
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "PaymentSupabaseDataSource")

    init(client: SupabaseClient) {
        self.client = client
    }

    // MARK: - Fetch Operations

    func fetchAll(userId: UUID) async throws -> [PaymentDTO] {
        logger.info("📥 Fetching all payments for user: \(userId)")

        let response: [PaymentDTO] = try await client
            .from(tableName)
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        logger.info("✅ Fetched \(response.count) payments")
        return response
    }

    func fetchFiltered(userId: UUID, from: Date?, to: Date?) async throws -> [PaymentDTO] {
        logger.info("📥 Fetching filtered payments for user: \(userId)")

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

        let response: [PaymentDTO] = try await query.execute().value
        logger.info("✅ Fetched \(response.count) filtered payments")
        return response
    }

    // MARK: - Upsert Operations

    func upsert(_ payment: PaymentDTO, userId: UUID) async throws {
        logger.info("📤 Upserting payment: \(payment.name)")

        try await client
            .from(tableName)
            .upsert(payment)
            .execute()

        logger.info("✅ Payment upserted: \(payment.name)")
    }

    func upsertAll(_ payments: [PaymentDTO], userId: UUID) async throws {
        guard !payments.isEmpty else {
            logger.info("⚠️ No payments to upsert")
            return
        }

        logger.info("📤 Upserting \(payments.count) payments")

        try await client
            .from(tableName)
            .upsert(payments)
            .execute()

        logger.info("✅ \(payments.count) payments upserted")
    }

    // MARK: - Delete Operations

    func delete(id: UUID) async throws {
        logger.info("🗑️ Deleting payment: \(id)")

        try await client
            .from(tableName)
            .delete()
            .eq("id", value: id.uuidString)
            .execute()

        logger.info("✅ Payment deleted: \(id)")
    }

    func deleteAll(ids: [UUID]) async throws {
        guard !ids.isEmpty else {
            logger.info("⚠️ No payments to delete")
            return
        }

        logger.info("🗑️ Deleting \(ids.count) payments")

        let uuidStrings = ids.map { $0.uuidString }
        try await client
            .from(tableName)
            .delete()
            .in("id", values: uuidStrings)
            .execute()

        logger.info("✅ \(ids.count) payments deleted")
    }
}
