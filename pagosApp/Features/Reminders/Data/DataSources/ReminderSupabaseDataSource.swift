//
//  ReminderSupabaseDataSource.swift
//  pagosApp
//
//  Supabase implementation of ReminderRemoteDataSource.
//  Clean Architecture - Data Layer
//

import Foundation
import Supabase

final class ReminderSupabaseDataSource: ReminderRemoteDataSource {
    private let client: SupabaseClient
    private let tableName = "reminders"
    private let defaultPageSize = 200

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchAll(userId: UUID) async throws -> [ReminderDTO] {
        var all: [ReminderDTO] = []
        var offset = 0

        while true {
            NetworkDebugLogger.logRequest(
                "fetchPage",
                resource: tableName,
                details: [
                    "userId": NetworkDebugLogger.redactIdentifier(userId.uuidString),
                    "limit": "\(defaultPageSize)",
                    "offset": "\(offset)"
                ]
            )

            do {
                let page: [ReminderDTO] = try await client
                    .from(tableName)
                    .select()
                    .eq("user_id", value: userId.uuidString)
                    .range(from: offset, to: offset + defaultPageSize - 1)
                    .execute()
                    .value

                NetworkDebugLogger.logResponse("fetchPage", resource: tableName, details: ["count": "\(page.count)"])
                all.append(contentsOf: page)
                if page.count < defaultPageSize {
                    break
                }
                offset += defaultPageSize
            } catch {
                NetworkDebugLogger.logFailure("fetchAll", resource: tableName, error: error)
                throw error
            }
        }

        return all
    }

    func upsert(_ reminder: ReminderDTO, userId: UUID) async throws {
        NetworkDebugLogger.logRequest(
            "upsert",
            resource: tableName,
            details: ["userId": NetworkDebugLogger.redactIdentifier(userId.uuidString)]
        )
        do {
            try await client
                .from(tableName)
                .upsert(reminder)
                .execute()
            NetworkDebugLogger.logResponse("upsert", resource: tableName)
        } catch {
            NetworkDebugLogger.logFailure("upsert", resource: tableName, error: error)
            throw error
        }
    }

    func upsertAll(_ reminders: [ReminderDTO], userId: UUID) async throws {
        guard !reminders.isEmpty else { return }
        NetworkDebugLogger.logRequest(
            "upsertAll",
            resource: tableName,
            details: [
                "userId": NetworkDebugLogger.redactIdentifier(userId.uuidString),
                "count": "\(reminders.count)"
            ]
        )
        do {
            try await client
                .from(tableName)
                .upsert(reminders)
                .execute()
            NetworkDebugLogger.logResponse("upsertAll", resource: tableName, details: ["count": "\(reminders.count)"])
        } catch {
            NetworkDebugLogger.logFailure("upsertAll", resource: tableName, error: error)
            throw error
        }
    }

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
