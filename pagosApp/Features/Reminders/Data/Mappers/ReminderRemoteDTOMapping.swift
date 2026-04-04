//
//  ReminderRemoteDTOMapping.swift  
//  pagosApp
//
//  Protocol for reminder remote DTO mapping to match payment patterns.
//  Clean Architecture - Data Layer
//

import Foundation

/// Protocol for mapping between Reminder domain objects and ReminderDTO (remote)
/// Follows the same pattern as PaymentUIMapping for consistency
protocol ReminderRemoteDTOMapping {
    /// Convert remote DTO to domain entity
    func toDomain(_ dto: ReminderDTO) -> Reminder
    
    /// Convert multiple remote DTOs to domain entities
    func toDomain(_ dtos: [ReminderDTO]) -> [Reminder]
    
    /// Convert domain entity to remote DTO
    func toRemoteDTO(_ reminder: Reminder, userId: UUID) -> ReminderDTO
}

/// Default implementation of ReminderRemoteDTOMapping
struct ReminderRemoteDTOMapper: ReminderRemoteDTOMapping {
    
    func toDomain(_ dto: ReminderDTO) -> Reminder {
        Reminder(
            id: dto.id,
            reminderType: ReminderType.from(storedRawValue: dto.reminderType),
            title: dto.title,
            description: dto.reminderDescription,
            dueDate: dto.dueDate,
            isCompleted: dto.isCompleted,
            notificationSettings: dto.notificationSettings ?? NotificationSettings(), // Default for migration
            syncStatus: .synced,
            lastSyncedAt: dto.updatedAt ?? dto.createdAt
        )
    }

    func toDomain(_ dtos: [ReminderDTO]) -> [Reminder] {
        dtos.map { toDomain($0) }
    }

    func toRemoteDTO(_ reminder: Reminder, userId: UUID) -> ReminderDTO {
        ReminderDTO(
            id: reminder.id,
            userId: userId,
            reminderType: reminder.reminderType.rawValue,
            title: reminder.title,
            reminderDescription: reminder.description,
            dueDate: reminder.dueDate,
            isCompleted: reminder.isCompleted,
            notificationSettings: reminder.notificationSettings,
            createdAt: Date(), // This would typically be provided by the backend
            updatedAt: Date()
        )
    }
}