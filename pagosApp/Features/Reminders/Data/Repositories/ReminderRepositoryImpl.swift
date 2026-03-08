//
//  ReminderRepositoryImpl.swift
//  pagosApp
//
//  Repository implementation for reminders (local + notifications).
//  Clean Architecture - Data Layer. Uses domain types only at boundary, like Payment.
//

import Foundation
import OSLog

@MainActor
final class ReminderRepositoryImpl: ReminderRepositoryProtocol {
    private let localDataSource: ReminderLocalDataSource
    private let notificationDataSource: NotificationDataSource
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "ReminderRepositoryImpl")

    init(localDataSource: ReminderLocalDataSource, notificationDataSource: NotificationDataSource) {
        self.localDataSource = localDataSource
        self.notificationDataSource = notificationDataSource
    }

    func create(reminder: Reminder) async -> Result<Reminder, ReminderError> {
        do {
            try await localDataSource.save(reminder)
            notificationDataSource.scheduleReminderNotifications(reminderId: reminder.id, title: reminder.title, dueDate: reminder.dueDate)
            return .success(reminder)
        } catch {
            logger.error("❌ Failed to create reminder: \(error.localizedDescription)")
            return .failure(.saveFailed(error.localizedDescription))
        }
    }

    func getAll() async -> Result<[Reminder], ReminderError> {
        do {
            let reminders = try await localDataSource.fetchAll()
            return .success(reminders)
        } catch {
            logger.error("❌ Failed to fetch reminders: \(error.localizedDescription)")
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func getById(id: UUID) async -> Result<Reminder?, ReminderError> {
        do {
            let reminder = try await localDataSource.fetch(id: id)
            return .success(reminder)
        } catch {
            logger.error("❌ Failed to fetch reminder: \(error.localizedDescription)")
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func update(reminder: Reminder) async -> Result<Reminder, ReminderError> {
        do {
            notificationDataSource.cancelReminderNotifications(reminderId: reminder.id)
            try await localDataSource.save(reminder)
            notificationDataSource.scheduleReminderNotifications(reminderId: reminder.id, title: reminder.title, dueDate: reminder.dueDate)
            return .success(reminder)
        } catch {
            logger.error("❌ Failed to update reminder: \(error.localizedDescription)")
            return .failure(.saveFailed(error.localizedDescription))
        }
    }

    func delete(id: UUID) async -> Result<Void, ReminderError> {
        do {
            notificationDataSource.cancelReminderNotifications(reminderId: id)
            try await localDataSource.delete(id: id)
            return .success(())
        } catch {
            logger.error("❌ Failed to delete reminder: \(error.localizedDescription)")
            return .failure(.deleteFailed(error.localizedDescription))
        }
    }
}
