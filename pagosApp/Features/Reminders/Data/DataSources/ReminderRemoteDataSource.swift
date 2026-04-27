//
//  ReminderRemoteDataSource.swift
//  pagosApp
//
//  Protocol for reminder remote data source (Supabase).
//  Clean Architecture - Data Layer
//

import Foundation

/// Protocol for remote reminder operations (Supabase table `reminders`)
protocol ReminderRemoteDataSource: Sendable {
    func fetchAll(userId: UUID) async throws -> [ReminderDTO]
    func upsert(_ reminder: ReminderDTO, userId: UUID) async throws
    func upsertAll(_ reminders: [ReminderDTO], userId: UUID) async throws
    func delete(id: UUID) async throws
    func deleteAll(ids: [UUID]) async throws
}
