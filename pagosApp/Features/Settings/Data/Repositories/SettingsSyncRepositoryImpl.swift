//
//  SettingsSyncRepositoryImpl.swift
//  pagosApp
//
//  Repository implementation for settings sync operations
//  Clean Architecture - Data Layer
//

import Foundation

/// Implementation of SettingsSyncRepositoryProtocol
/// Delegates to PaymentSyncCoordinator and ReminderSyncCoordinator
@MainActor
final class SettingsSyncRepositoryImpl: SettingsSyncRepositoryProtocol {
    private static let logCategory = "SettingsSyncRepositoryImpl"

    private let paymentSyncCoordinator: PaymentSyncCoordinator
    private let reminderSyncCoordinator: ReminderSyncCoordinator
    private let log: DomainLogWriter

    init(
        paymentSyncCoordinator: PaymentSyncCoordinator,
        reminderSyncCoordinator: ReminderSyncCoordinator,
        log: DomainLogWriter
    ) {
        self.paymentSyncCoordinator = paymentSyncCoordinator
        self.reminderSyncCoordinator = reminderSyncCoordinator
        self.log = log
    }

    func performSync() async throws {
        log.info("🔄 Performing sync via settings (payments + reminders)", category: Self.logCategory)
        try await paymentSyncCoordinator.performSync()
        try await reminderSyncCoordinator.performSync()
    }

    func clearLocalDatabase(force: Bool) async -> Bool {
        log.info("🗑️ Clearing local database via settings (force: \(force))", category: Self.logCategory)
        let paymentsCleared = await paymentSyncCoordinator.clearLocalDatabase(force: force)
        let remindersCleared = await reminderSyncCoordinator.clearLocalDatabase(force: force)
        return paymentsCleared && remindersCleared
    }

    func updatePendingSyncCount() async {
        log.debug("📊 Updating pending sync count", category: Self.logCategory)
        await paymentSyncCoordinator.updatePendingSyncCount()
        await reminderSyncCoordinator.updatePendingSyncCount()
    }

    var pendingSyncCount: Int {
        paymentSyncCoordinator.pendingSyncCount + reminderSyncCoordinator.pendingSyncCount
    }

    var syncError: Error? {
        paymentSyncCoordinator.syncError ?? reminderSyncCoordinator.syncError
    }
}
