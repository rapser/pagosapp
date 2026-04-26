//
//  ReminderRepositoryImpl.swift
//  pagosApp
//
//  Repository implementation for reminders (local + notifications).
//  Clean Architecture - Data Layer. Uses domain types only at boundary, like Payment.
//

import Foundation

final class ReminderRepositoryImpl: ReminderRepositoryProtocol, @unchecked Sendable {
    private static let logCategory = "ReminderRepositoryImpl"

    private let localDataSource: ReminderLocalDataSource
    private let notificationDataSource: NotificationDataSource
    private let log: DomainLogWriter

    init(
        localDataSource: ReminderLocalDataSource,
        notificationDataSource: NotificationDataSource,
        log: DomainLogWriter
    ) {
        self.localDataSource = localDataSource
        self.notificationDataSource = notificationDataSource
        self.log = log
    }

    @MainActor
    func create(reminder: Reminder) async -> Result<Reminder, ReminderError> {
        log.info("📝 Creating reminder: \(reminder.title)", category: Self.logCategory)
        do {
            try await localDataSource.save(reminder)
            log.info("✅ Reminder saved successfully, scheduling notifications...", category: Self.logCategory)
            notificationDataSource.scheduleReminderNotifications(
                reminderId: reminder.id,
                title: reminder.title,
                dueDate: reminder.dueDate,
                notificationSettings: reminder.notificationSettings
            )
            log.info("✅ Reminder created successfully with notifications", category: Self.logCategory)
            return .success(reminder)
        } catch {
            log.error("❌ Failed to create reminder: \(error.localizedDescription)", category: Self.logCategory)
            return .failure(.saveFailed(error.localizedDescription))
        }
    }

    @MainActor
    func getAll() async -> Result<[Reminder], ReminderError> {
        do {
            let reminders = try await localDataSource.fetchAll()
            return .success(reminders)
        } catch {
            log.error("❌ Failed to fetch reminders: \(error.localizedDescription)", category: Self.logCategory)
            return .failure(.unknown(error.localizedDescription))
        }
    }

    @MainActor
    func getById(id: UUID) async -> Result<Reminder?, ReminderError> {
        do {
            let reminder = try await localDataSource.fetch(id: id)
            return .success(reminder)
        } catch {
            log.error("❌ Failed to fetch reminder: \(error.localizedDescription)", category: Self.logCategory)
            return .failure(.unknown(error.localizedDescription))
        }
    }

    @MainActor
    func update(reminder: Reminder) async -> Result<Reminder, ReminderError> {
        log.info("📝 Updating reminder: \(reminder.title)", category: Self.logCategory)
        do {
            notificationDataSource.cancelReminderNotifications(reminderId: reminder.id)
            try await localDataSource.save(reminder)
            if !reminder.isCompleted {
                log.info("🔔 Reminder not completed, scheduling notifications...", category: Self.logCategory)
                notificationDataSource.scheduleReminderNotifications(
                    reminderId: reminder.id,
                    title: reminder.title,
                    dueDate: reminder.dueDate,
                    notificationSettings: reminder.notificationSettings
                )
            } else {
                log.info("✅ Reminder completed, notifications cancelled", category: Self.logCategory)
            }
            return .success(reminder)
        } catch {
            log.error("❌ Failed to update reminder: \(error.localizedDescription)", category: Self.logCategory)
            return .failure(.saveFailed(error.localizedDescription))
        }
    }

    @MainActor
    func delete(id: UUID) async -> Result<Void, ReminderError> {
        do {
            notificationDataSource.cancelReminderNotifications(reminderId: id)
            try await localDataSource.delete(id: id)
            return .success(())
        } catch {
            log.error("❌ Failed to delete reminder: \(error.localizedDescription)", category: Self.logCategory)
            return .failure(.deleteFailed(error.localizedDescription))
        }
    }
}
