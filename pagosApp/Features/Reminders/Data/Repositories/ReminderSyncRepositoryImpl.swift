//
//  ReminderSyncRepositoryImpl.swift
//  pagosApp
//
//  Implementation of ReminderSyncRepositoryProtocol.
//  Clean Architecture - Data Layer
//

import Foundation
import Supabase
import OSLog

@MainActor
final class ReminderSyncRepositoryImpl: ReminderSyncRepositoryProtocol {
    private let remoteDataSource: ReminderRemoteDataSource
    private let localDataSource: ReminderLocalDataSource
    private let supabaseClient: SupabaseClient
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "ReminderSyncRepositoryImpl")

    init(
        remoteDataSource: ReminderRemoteDataSource,
        localDataSource: ReminderLocalDataSource,
        supabaseClient: SupabaseClient
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
        self.supabaseClient = supabaseClient
    }

    func getCurrentUserId() async throws -> UUID {
        guard let userId = supabaseClient.auth.currentUser?.id else {
            logger.error("❌ No authenticated user")
            throw ReminderSyncError.notAuthenticated
        }
        return userId
    }

    func uploadReminders(_ reminders: [Reminder], userId: UUID) async throws {
        logger.info("📤 Uploading \(reminders.count) reminders")
        let dtos = ReminderRemoteMapper.toRemoteDTO(reminders, userId: userId)
        try await remoteDataSource.upsertAll(dtos, userId: userId)

        let now = Date()
        for reminder in reminders {
            let updated = Reminder(
                id: reminder.id,
                reminderType: reminder.reminderType,
                title: reminder.title,
                dueDate: reminder.dueDate,
                syncStatus: .synced,
                lastSyncedAt: now
            )
            try await localDataSource.save(updated)
        }
        logger.info("✅ \(reminders.count) reminders uploaded and marked as synced")
    }

    func downloadReminders(userId: UUID) async throws -> [Reminder] {
        logger.info("📥 Downloading reminders for user: \(userId)")
        let dtos = try await remoteDataSource.fetchAll(userId: userId)
        let entities = ReminderRemoteMapper.toDomain(dtos)
        logger.info("✅ Downloaded \(entities.count) reminders")
        return entities
    }

    func syncDeletion(reminderId: UUID) async throws {
        logger.info("🗑️ Syncing deletion of reminder: \(reminderId)")
        try await remoteDataSource.delete(id: reminderId)
        logger.info("✅ Reminder deletion synced")
    }

    func getPendingReminders() async throws -> [Reminder] {
        let all = try await localDataSource.fetchAll()
        let pending = all.filter { r in
            r.syncStatus == .local || r.syncStatus == .modified || r.syncStatus == .error
        }
        logger.debug("✅ Found \(pending.count) pending reminders")
        return pending
    }

    func getPendingSyncCount() async throws -> Int {
        let pending = try await getPendingReminders()
        return pending.count
    }

    func updateSyncStatus(reminderId: UUID, status: ReminderSyncStatus) async throws {
        logger.debug("🔄 Updating sync status for \(reminderId) to \(status.rawValue)")
        guard let reminder = try await localDataSource.fetch(id: reminderId) else {
            logger.warning("⚠️ Reminder not found: \(reminderId)")
            return
        }
        let updated = Reminder(
            id: reminder.id,
            reminderType: reminder.reminderType,
            title: reminder.title,
            dueDate: reminder.dueDate,
            syncStatus: status,
            lastSyncedAt: status == .synced ? Date() : reminder.lastSyncedAt
        )
        try await localDataSource.save(updated)
        logger.debug("✅ Sync status updated")
    }
}
