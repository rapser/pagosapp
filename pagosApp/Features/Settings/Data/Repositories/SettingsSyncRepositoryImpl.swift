//
//  SettingsSyncRepositoryImpl.swift
//  pagosApp
//
//  Repository implementation for settings sync operations
//  Clean Architecture - Data Layer
//

import Foundation

/// Implementation of SettingsSyncRepositoryProtocol
/// Delegates to payment and reminder sync ports (concrete coordinators conform at the boundary).
@MainActor
final class SettingsSyncRepositoryImpl: SettingsSyncRepositoryProtocol {
    private static let logCategory = "SettingsSyncRepositoryImpl"

    private let paymentSync: PaymentSyncCoordinating
    private let reminderSync: ReminderSyncCoordinating
    private let log: DomainLogWriter

    init(
        paymentSync: PaymentSyncCoordinating,
        reminderSync: ReminderSyncCoordinating,
        log: DomainLogWriter
    ) {
        self.paymentSync = paymentSync
        self.reminderSync = reminderSync
        self.log = log
    }

    func performSync() async throws {
        log.info("🔄 Performing sync via settings (payments + reminders)", category: Self.logCategory)
        try await paymentSync.performSync()
        try await reminderSync.performSync()
    }

    func clearLocalDatabase(force: Bool) async -> Bool {
        log.info("🗑️ Clearing local database via settings (force: \(force))", category: Self.logCategory)
        let paymentsCleared = await paymentSync.clearLocalDatabase(force: force)
        let remindersCleared = await reminderSync.clearLocalDatabase(force: force)
        return paymentsCleared && remindersCleared
    }

    func updatePendingSyncCount() async {
        log.debug("📊 Updating pending sync count", category: Self.logCategory)
        await paymentSync.updatePendingSyncCount()
        await reminderSync.updatePendingSyncCount()
    }

    var pendingSyncCount: Int {
        paymentSync.pendingSyncCount + reminderSync.pendingSyncCount
    }

    var syncError: Error? {
        paymentSync.syncError ?? reminderSync.syncError
    }
}
