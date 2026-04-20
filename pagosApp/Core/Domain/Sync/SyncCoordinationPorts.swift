//
//  SyncCoordinationPorts.swift
//  pagosApp
//
//  Domain-facing ports for cross-feature sync coordination (no concrete coordinator types).
//

import Foundation

/// Port for payment sync entry points used by `CoordinateSyncUseCase`, session unlink, settings, and UI aggregation.
@MainActor
protocol PaymentSyncCoordinating: AnyObject {
    var isSyncing: Bool { get }
    var lastSyncDate: Date? { get }
    var pendingSyncCount: Int { get }
    var syncError: Error? { get }

    func performInitialSyncIfNeeded(isAuthenticated: Bool) async
    func performSync() async throws
    func updatePendingSyncCount() async
    @discardableResult
    func clearLocalDatabase(force: Bool) async -> Bool
}

/// Port for reminder sync used by `CoordinateSyncUseCase`, session unlink, settings, and UI aggregation.
@MainActor
protocol ReminderSyncCoordinating: AnyObject {
    var isSyncing: Bool { get }
    var lastSyncDate: Date? { get }
    var pendingSyncCount: Int { get }
    var syncError: Error? { get }

    func performSync() async throws
    func updatePendingSyncCount() async
    @discardableResult
    func clearLocalDatabase(force: Bool) async -> Bool
}
