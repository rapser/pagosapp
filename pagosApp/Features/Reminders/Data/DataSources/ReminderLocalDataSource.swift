//
//  ReminderLocalDataSource.swift
//  pagosApp
//
//  Local data source for reminders (SwiftData).
//  Clean Architecture - Data Layer. Protocol returns domain types (Sendable) like PaymentLocalDataSource.
//

import Foundation
import SwiftData
import OSLog

protocol ReminderLocalDataSource {
    func fetchAll() async throws -> [Reminder]
    func fetchPaginated(page: Int, pageSize: Int) async throws -> [Reminder]
    func fetchCount() async throws -> Int
    func fetch(id: UUID) async throws -> Reminder?
    func save(_ reminder: Reminder) async throws
    func saveAll(_ reminders: [Reminder]) async throws
    func delete(id: UUID) async throws
}

@MainActor
final class ReminderSwiftDataDataSource: ReminderLocalDataSource {
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "ReminderSwiftDataDataSource")

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() async throws -> [Reminder] {
        let descriptor = FetchDescriptor<ReminderLocalDTO>(sortBy: [SortDescriptor(\.dueDate)])
        do {
            let dtos = try modelContext.fetch(descriptor)
            return dtos.map { ReminderDomainMapper.toDomain($0) }
        } catch {
            logger.error("Failed to fetch reminders from SwiftData: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchPaginated(page: Int, pageSize: Int) async throws -> [Reminder] {
        var descriptor = FetchDescriptor<ReminderLocalDTO>(sortBy: [SortDescriptor(\.dueDate)])
        descriptor.fetchOffset = (page - 1) * pageSize
        descriptor.fetchLimit = pageSize
        
        do {
            let dtos = try modelContext.fetch(descriptor)
            return dtos.map { ReminderDomainMapper.toDomain($0) }
        } catch {
            logger.error("Failed to fetch paginated reminders: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchCount() async throws -> Int {
        let descriptor = FetchDescriptor<ReminderLocalDTO>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
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
            existing.isCompleted = dto.isCompleted ?? false
            existing.notificationSettings = dto.notificationSettings
            existing.syncStatusRawValue = dto.syncStatusRawValue
            existing.lastSyncedAt = dto.lastSyncedAt
        } else {
            let dto = ReminderDomainMapper.toDTO(reminder)
            modelContext.insert(dto)
        }
        try modelContext.save()
    }

    func saveAll(_ reminders: [Reminder]) async throws {
        guard !reminders.isEmpty else { return }
        
        // Optimized: batch fetch existing IDs to minimize DB round trips
        let reminderIds = reminders.map { $0.id }
        let predicate = #Predicate<ReminderLocalDTO> { dto in
            reminderIds.contains(dto.id)
        }
        let descriptor = FetchDescriptor<ReminderLocalDTO>(predicate: predicate)
        let existingDTOs = try modelContext.fetch(descriptor)
        let existingById = Dictionary(uniqueKeysWithValues: existingDTOs.map { ($0.id, $0) })
        
        for reminder in reminders {
            let dto = ReminderDomainMapper.toDTO(reminder)
            if let existing = existingById[reminder.id] {
                existing.reminderType = dto.reminderType
                existing.title = dto.title
                existing.reminderDescription = dto.reminderDescription ?? ""
                existing.dueDate = dto.dueDate
                existing.isCompleted = dto.isCompleted ?? false
                existing.notificationSettings = dto.notificationSettings
                existing.syncStatusRawValue = dto.syncStatusRawValue
                existing.lastSyncedAt = dto.lastSyncedAt
            } else {
                modelContext.insert(dto)
            }
        }
        
        try modelContext.save()
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
