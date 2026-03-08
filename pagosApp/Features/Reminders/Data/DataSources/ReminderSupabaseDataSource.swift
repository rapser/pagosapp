//
//  ReminderSupabaseDataSource.swift
//  pagosApp
//
//  Supabase implementation of ReminderRemoteDataSource.
//  Clean Architecture - Data Layer
//

import Foundation
import Supabase
import OSLog

final class ReminderSupabaseDataSource: ReminderRemoteDataSource {
    private let client: SupabaseClient
    private let tableName = "reminders"
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "ReminderSupabaseDataSource")

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchAll(userId: UUID) async throws -> [ReminderDTO] {
        logger.info("📥 Fetching all reminders for user: \(userId)")
        let response: [ReminderDTO] = try await client
            .from(tableName)
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        logger.info("✅ Fetched \(response.count) reminders")
        return response
    }

    func upsert(_ reminder: ReminderDTO, userId: UUID) async throws {
        logger.info("📤 Upserting reminder: \(reminder.title)")
        try await client
            .from(tableName)
            .upsert(reminder)
            .execute()
        logger.info("✅ Reminder upserted: \(reminder.title)")
    }

    func upsertAll(_ reminders: [ReminderDTO], userId: UUID) async throws {
        guard !reminders.isEmpty else {
            logger.info("⚠️ No reminders to upsert")
            return
        }
        logger.info("📤 Upserting \(reminders.count) reminders")
        try await client
            .from(tableName)
            .upsert(reminders)
            .execute()
        logger.info("✅ \(reminders.count) reminders upserted")
    }

    func delete(id: UUID) async throws {
        logger.info("🗑️ Deleting reminder: \(id)")
        try await client
            .from(tableName)
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
        logger.info("✅ Reminder deleted: \(id)")
    }

    func deleteAll(ids: [UUID]) async throws {
        guard !ids.isEmpty else {
            logger.info("⚠️ No reminders to delete")
            return
        }
        logger.info("🗑️ Deleting \(ids.count) reminders")
        let uuidStrings = ids.map { $0.uuidString }
        try await client
            .from(tableName)
            .delete()
            .in("id", values: uuidStrings)
            .execute()
        logger.info("✅ \(ids.count) reminders deleted")
    }
}
