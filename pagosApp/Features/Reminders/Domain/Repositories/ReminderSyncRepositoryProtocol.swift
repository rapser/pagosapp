//
//  ReminderSyncRepositoryProtocol.swift
//  pagosApp
//
//  Repository protocol for reminder synchronization with Supabase.
//  Clean Architecture - Domain Layer
//

import Foundation

/// Repository protocol for reminder sync operations
protocol ReminderSyncRepositoryProtocol {
    func getCurrentUserId() async throws -> UUID
    func uploadReminders(_ reminders: [Reminder], userId: UUID) async throws
    func downloadReminders(userId: UUID) async throws -> [Reminder]
    func syncDeletion(reminderId: UUID) async throws
    func getPendingReminders() async throws -> [Reminder]
    func getPendingSyncCount() async throws -> Int
    func updateSyncStatus(reminderId: UUID, status: ReminderSyncStatus) async throws
}
