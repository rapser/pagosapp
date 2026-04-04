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
    private let remoteMapper: ReminderRemoteDTOMapping

    init(
        remoteDataSource: ReminderRemoteDataSource,
        localDataSource: ReminderLocalDataSource,
        supabaseClient: SupabaseClient,
        remoteMapper: ReminderRemoteDTOMapping
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
        self.supabaseClient = supabaseClient
        self.remoteMapper = remoteMapper
    }

    func getCurrentUserId() async throws -> UUID {
        guard let userId = supabaseClient.auth.currentUser?.id else {
            throw ReminderSyncError.notAuthenticated
        }
        return userId
    }

    func uploadReminders(_ reminders: [Reminder], userId: UUID) async throws {
        let dtos = reminders.map { remoteMapper.toRemoteDTO($0, userId: userId) }
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
                notificationSettings: reminder.notificationSettings,
                syncStatus: .synced,
                lastSyncedAt: now
            )
            try await localDataSource.save(updated)
        }
    }

    func downloadReminders(userId: UUID) async throws -> [Reminder] {
        let dtos = try await remoteDataSource.fetchAll(userId: userId)
        return remoteMapper.toDomain(dtos)
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
            notificationSettings: reminder.notificationSettings,
            syncStatus: status,
            lastSyncedAt: status == .synced ? Date() : reminder.lastSyncedAt
        )
        try await localDataSource.save(updated)
    }
}
