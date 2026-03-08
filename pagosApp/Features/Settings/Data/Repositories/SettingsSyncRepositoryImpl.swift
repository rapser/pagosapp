//
//  SettingsSyncRepositoryImpl.swift
//  pagosApp
//
//  Repository implementation for settings sync operations
//  Clean Architecture - Data Layer
//

import Foundation
import OSLog

/// Implementation of SettingsSyncRepositoryProtocol
/// Delegates to PaymentSyncCoordinator and ReminderSyncCoordinator
@MainActor
final class SettingsSyncRepositoryImpl: SettingsSyncRepositoryProtocol {
    private let paymentSyncCoordinator: PaymentSyncCoordinator
    private let reminderSyncCoordinator: ReminderSyncCoordinator
    private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "SettingsSyncRepository")

    init(paymentSyncCoordinator: PaymentSyncCoordinator, reminderSyncCoordinator: ReminderSyncCoordinator) {
        self.paymentSyncCoordinator = paymentSyncCoordinator
        self.reminderSyncCoordinator = reminderSyncCoordinator
    }

    func performSync() async throws {
        logger.info("🔄 Performing sync via settings (payments + reminders)")
        try await paymentSyncCoordinator.performSync()
        try await reminderSyncCoordinator.performSync()
    }

    func clearLocalDatabase(force: Bool) async -> Bool {
        logger.info("🗑️ Clearing local database via settings (force: \(force))")
        let paymentsCleared = await paymentSyncCoordinator.clearLocalDatabase(force: force)
        let remindersCleared = await reminderSyncCoordinator.clearLocalDatabase(force: force)
        return paymentsCleared && remindersCleared
    }

    func updatePendingSyncCount() async {
        logger.debug("📊 Updating pending sync count")
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
