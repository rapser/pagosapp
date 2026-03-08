//
//  ReminderLocalDataSource.swift
//  pagosApp
//
//  Local data source for reminders (SwiftData).
//  Clean Architecture - Data Layer. Protocol returns domain types (Sendable) like PaymentLocalDataSource.
//

import Foundation
import SwiftData

protocol ReminderLocalDataSource {
    func fetchAll() async throws -> [Reminder]
    func fetch(id: UUID) async throws -> Reminder?
    func save(_ reminder: Reminder) async throws
    func saveAll(_ reminders: [Reminder]) async throws
    func delete(id: UUID) async throws
}

@MainActor
final class ReminderSwiftDataDataSource: ReminderLocalDataSource {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() async throws -> [Reminder] {
        let descriptor = FetchDescriptor<ReminderLocalDTO>(sortBy: [SortDescriptor(\.dueDate)])
        let dtos = try modelContext.fetch(descriptor)
        return dtos.map { ReminderDomainMapper.toDomain($0) }
    }

    func fetch(id: UUID) async throws -> Reminder? {
        let searchId = id
        var descriptor = FetchDescriptor<ReminderLocalDTO>(predicate: #Predicate<ReminderLocalDTO> { dto in
            dto.id == searchId
        })
        descriptor.fetchLimit = 1
        guard let dto = try modelContext.fetch(descriptor).first else {
            return nil
        }
        return ReminderDomainMapper.toDomain(dto)
    }

    func save(_ reminder: Reminder) async throws {
        let reminderId = reminder.id
        var descriptor = FetchDescriptor<ReminderLocalDTO>(predicate: #Predicate<ReminderLocalDTO> { dto in
            dto.id == reminderId
        })
        descriptor.fetchLimit = 1
        let existing = try modelContext.fetch(descriptor).first
        if let existing = existing {
            let dto = ReminderDomainMapper.toDTO(reminder)
            existing.reminderType = dto.reminderType
            existing.title = dto.title
            existing.reminderDescription = dto.reminderDescription ?? ""
            existing.dueDate = dto.dueDate
            existing.syncStatusRawValue = dto.syncStatusRawValue
            existing.lastSyncedAt = dto.lastSyncedAt
        } else {
            let dto = ReminderDomainMapper.toDTO(reminder)
            modelContext.insert(dto)
        }
        try modelContext.save()
    }

    func saveAll(_ reminders: [Reminder]) async throws {
        for reminder in reminders {
            try await save(reminder)
        }
    }

    func delete(id: UUID) async throws {
        let searchId = id
        var descriptor = FetchDescriptor<ReminderLocalDTO>(predicate: #Predicate<ReminderLocalDTO> { dto in
            dto.id == searchId
        })
        descriptor.fetchLimit = 1
        guard let dto = try modelContext.fetch(descriptor).first else {
            return
        }
        modelContext.delete(dto)
        try modelContext.save()
    }
}
