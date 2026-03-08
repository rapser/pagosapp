//
//  ReminderRepositoryProtocol.swift
//  pagosApp
//
//  Domain repository protocol for Reminders (local-only).
//

import Foundation

protocol ReminderRepositoryProtocol {
    func create(reminder: Reminder) async -> Result<Reminder, ReminderError>
    func getAll() async -> Result<[Reminder], ReminderError>
    func getById(id: UUID) async -> Result<Reminder?, ReminderError>
    func update(reminder: Reminder) async -> Result<Reminder, ReminderError>
    func delete(id: UUID) async -> Result<Void, ReminderError>
}
