//
//  ReminderSyncRepositoryProtocol.swift
//  pagosApp
//
//  Repository protocol for reminder synchronization with Supabase.
//  Clean Architecture - Domain Layer
//

import Foundation

/// Repository protocol for reminder sync operations
protocol ReminderSyncRepositoryProtocol: Sendable {
    func getCurrentUserId() async throws -> UUID
    @MainActor
    func uploadReminders(_ reminders: [Reminder], userId: UUID) async throws
    func downloadReminders(userId: UUID) async throws -> [Reminder]
    func syncDeletion(reminderId: UUID) async throws
    @MainActor
    func getPendingDeletionIds() async throws -> [UUID]
    /// Deletes the reminders from Supabase and then purges their local tombstones.
    @MainActor
    func uploadDeletions(_ ids: [UUID]) async throws
    @MainActor
    func getPendingReminders() async throws -> [Reminder]
    @MainActor
    func getPendingSyncCount() async throws -> Int
    @MainActor
    func updateSyncStatus(reminderId: UUID, status: ReminderSyncStatus) async throws
}
