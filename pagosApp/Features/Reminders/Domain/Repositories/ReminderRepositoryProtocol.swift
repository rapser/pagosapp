//
//  ReminderRepositoryProtocol.swift
//  pagosApp
//
//  Domain repository protocol for Reminders (local-only).
//

import Foundation

protocol ReminderRepositoryProtocol: Sendable {
    @MainActor
    func create(reminder: Reminder) async -> Result<Reminder, ReminderError>
    @MainActor
    func getAll() async -> Result<[Reminder], ReminderError>
    @MainActor
    func getById(id: UUID) async -> Result<Reminder?, ReminderError>
    @MainActor
    func update(reminder: Reminder) async -> Result<Reminder, ReminderError>
    @MainActor
    func delete(id: UUID) async -> Result<Void, ReminderError>
    /// Hides the reminder locally (tombstone) so its remote deletion can be retried on the next sync.
    @MainActor
    func markForDeletion(id: UUID) async -> Result<Void, ReminderError>
}
