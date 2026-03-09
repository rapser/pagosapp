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

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchAll(userId: UUID) async throws -> [ReminderDTO] {
        let response: [ReminderDTO] = try await client
            .from(tableName)
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        return response
    }

    func upsert(_ reminder: ReminderDTO, userId: UUID) async throws {
        try await client
            .from(tableName)
            .upsert(reminder)
            .execute()
    }

    func upsertAll(_ reminders: [ReminderDTO], userId: UUID) async throws {
        guard !reminders.isEmpty else { return }
        try await client
            .from(tableName)
            .upsert(reminders)
            .execute()
    }

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
