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
    func getPendingReminders() async throws -> [Reminder]
    @MainActor
    func getPendingSyncCount() async throws -> Int
    @MainActor
    func updateSyncStatus(reminderId: UUID, status: ReminderSyncStatus) async throws
}
