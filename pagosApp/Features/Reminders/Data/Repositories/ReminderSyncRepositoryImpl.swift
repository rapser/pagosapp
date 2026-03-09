//
//  ReminderSyncRepositoryImpl.swift
//  pagosApp
//
//  Implementation of ReminderSyncRepositoryProtocol.
//  Clean Architecture - Data Layer
//

import Foundation
import Supabase

@MainActor
final class ReminderSyncRepositoryImpl: ReminderSyncRepositoryProtocol {
    private let remoteDataSource: ReminderRemoteDataSource
    private let localDataSource: ReminderLocalDataSource
    private let supabaseClient: SupabaseClient

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
            throw ReminderSyncError.notAuthenticated
        }
        return userId
    }

    func uploadReminders(_ reminders: [Reminder], userId: UUID) async throws {
        let dtos = ReminderRemoteMapper.toRemoteDTO(reminders, userId: userId)
        try await remoteDataSource.upsertAll(dtos, userId: userId)

        let now = Date()
        for reminder in reminders {
            let updated = Reminder(
                id: reminder.id,
                reminderType: reminder.reminderType,
                title: reminder.title,
                description: reminder.description,
                dueDate: reminder.dueDate,
                isCompleted: reminder.isCompleted,
                syncStatus: .synced,
                lastSyncedAt: now
            )
            try await localDataSource.save(updated)
        }
    }

    func downloadReminders(userId: UUID) async throws -> [Reminder] {
        let dtos = try await remoteDataSource.fetchAll(userId: userId)
        return ReminderRemoteMapper.toDomain(dtos)
    }

    func syncDeletion(reminderId: UUID) async throws {
        try await remoteDataSource.delete(id: reminderId)
    }

    func getPendingReminders() async throws -> [Reminder] {
        let all = try await localDataSource.fetchAll()
        return all.filter { r in
            r.syncStatus == .local || r.syncStatus == .modified || r.syncStatus == .error
        }
    }

    func getPendingSyncCount() async throws -> Int {
        let pending = try await getPendingReminders()
        return pending.count
    }

    func updateSyncStatus(reminderId: UUID, status: ReminderSyncStatus) async throws {
        guard let reminder = try await localDataSource.fetch(id: reminderId) else { return }
        let updated = Reminder(
            id: reminder.id,
            reminderType: reminder.reminderType,
            title: reminder.title,
            description: reminder.description,
            dueDate: reminder.dueDate,
            isCompleted: reminder.isCompleted,
            syncStatus: status,
            lastSyncedAt: status == .synced ? Date() : reminder.lastSyncedAt
        )
        try await localDataSource.save(updated)
    }
}
