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
    private let defaultPageSize = 200

    init(client: SupabaseClient) {
        self.client = client
    }

    // MARK: - Fetch Operations

    func fetchPage(userId: UUID, limit: Int, offset: Int) async throws -> [PaymentDTO] {
        NetworkDebugLogger.logRequest(
            "fetchPage",
            resource: tableName,
            details: [
                "userId": NetworkDebugLogger.redactIdentifier(userId.uuidString),
                "limit": "\(limit)",
                "offset": "\(offset)"
            ]
        )
        do {
            let response: [PaymentDTO] = try await client
                .from(tableName)
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("due_date", ascending: false)
                .range(from: offset, to: max(offset, offset + limit - 1))
                .execute()
                .value
            NetworkDebugLogger.logResponse(
                "fetchPage",
                resource: tableName,
                details: ["count": "\(response.count)"]
            )
            return response
        } catch {
            NetworkDebugLogger.logFailure("fetchPage", resource: tableName, error: error)
            throw error
        }
    }

    func fetchAll(userId: UUID) async throws -> [PaymentDTO] {
        var all: [PaymentDTO] = []
        var offset = 0

        while true {
            let page = try await fetchPage(userId: userId, limit: defaultPageSize, offset: offset)
            all.append(contentsOf: page)

            if page.count < defaultPageSize {
                break
            }
            offset += defaultPageSize
        }

        return all
    }

    func fetchFiltered(userId: UUID, from: Date?, to: Date?) async throws -> [PaymentDTO] {
        NetworkDebugLogger.logRequest(
            "fetchFiltered",
            resource: tableName,
            details: [
                "userId": NetworkDebugLogger.redactIdentifier(userId.uuidString),
                "from": from.map { ISO8601DateFormatter().string(from: $0) } ?? "-",
                "to": to.map { ISO8601DateFormatter().string(from: $0) } ?? "-"
            ]
        )
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
        do {
            let response: [PaymentDTO] = try await query
                .order("due_date", ascending: false)
                .execute()
                .value
            NetworkDebugLogger.logResponse(
                "fetchFiltered",
                resource: tableName,
                details: ["count": "\(response.count)"]
            )
            return response
        } catch {
            NetworkDebugLogger.logFailure("fetchFiltered", resource: tableName, error: error)
            throw error
        }
    }

    // MARK: - Upsert Operations

    func upsert(_ payment: PaymentDTO, userId: UUID) async throws {
        NetworkDebugLogger.logRequest(
            "upsert",
            resource: tableName,
            details: ["userId": NetworkDebugLogger.redactIdentifier(userId.uuidString)]
        )
        do {
            try await client
                .from(tableName)
                .upsert(payment)
                .execute()
            NetworkDebugLogger.logResponse("upsert", resource: tableName)
        } catch {
            NetworkDebugLogger.logFailure("upsert", resource: tableName, error: error)
            throw error
        }
    }

    func upsertAll(_ payments: [PaymentDTO], userId: UUID) async throws {
        guard !payments.isEmpty else { return }
        NetworkDebugLogger.logRequest(
            "upsertAll",
            resource: tableName,
            details: [
                "userId": NetworkDebugLogger.redactIdentifier(userId.uuidString),
                "count": "\(payments.count)"
            ]
        )
        do {
            try await client
                .from(tableName)
                .upsert(payments)
                .execute()
            NetworkDebugLogger.logResponse("upsertAll", resource: tableName, details: ["count": "\(payments.count)"])
        } catch {
            NetworkDebugLogger.logFailure("upsertAll", resource: tableName, error: error)
            throw error
        }
    }

    // MARK: - Delete Operations

    func delete(id: UUID) async throws {
        NetworkDebugLogger.logRequest(
            "delete",
            resource: tableName,
            details: ["id": NetworkDebugLogger.redactIdentifier(id.uuidString)]
        )
        do {
            try await client
                .from(tableName)
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
            NetworkDebugLogger.logResponse("delete", resource: tableName)
        } catch {
            NetworkDebugLogger.logFailure("delete", resource: tableName, error: error)
            throw error
        }
    }

    func deleteAll(ids: [UUID]) async throws {
        guard !ids.isEmpty else { return }
        let uuidStrings = ids.map { $0.uuidString }
        NetworkDebugLogger.logRequest(
            "deleteAll",
            resource: tableName,
            details: ["count": "\(ids.count)"]
        )
        do {
            try await client
                .from(tableName)
                .delete()
                .in("id", values: uuidStrings)
                .execute()
            NetworkDebugLogger.logResponse("deleteAll", resource: tableName, details: ["count": "\(ids.count)"])
        } catch {
            NetworkDebugLogger.logFailure("deleteAll", resource: tableName, error: error)
            throw error
        }
    }
}
