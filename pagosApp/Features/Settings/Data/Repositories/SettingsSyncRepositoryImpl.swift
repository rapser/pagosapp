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
/// Delegates to PaymentSyncCoordinator but provides Settings-specific interface
@MainActor
final class SettingsSyncRepositoryImpl: SettingsSyncRepositoryProtocol {
    private let paymentSyncCoordinator: PaymentSyncCoordinator
    private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "SettingsSyncRepository")

    init(paymentSyncCoordinator: PaymentSyncCoordinator) {
        self.paymentSyncCoordinator = paymentSyncCoordinator
    }

    func performSync() async throws {
        logger.info("🔄 Performing sync via settings")
        try await paymentSyncCoordinator.performSync()
    }

    func clearLocalDatabase(force: Bool) async -> Bool {
        logger.info("🗑️ Clearing local database via settings (force: \(force))")
        return await paymentSyncCoordinator.clearLocalDatabase(force: force)
    }

    func updatePendingSyncCount() async {
        logger.debug("📊 Updating pending sync count")
        await paymentSyncCoordinator.updatePendingSyncCount()
    }

    var pendingSyncCount: Int {
        paymentSyncCoordinator.pendingSyncCount
    }

    var syncError: PaymentSyncError? {
        paymentSyncCoordinator.syncError as? PaymentSyncError
    }
}
