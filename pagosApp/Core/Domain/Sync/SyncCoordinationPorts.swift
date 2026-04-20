//
//  SyncCoordinationPorts.swift
//  pagosApp
//
//  Domain-facing ports for cross-feature sync coordination (no concrete coordinator types).
//

import Foundation

/// Port for payment sync entry points used by `CoordinateSyncUseCase` and session unlink flows.
protocol PaymentSyncCoordinating: AnyObject {
    func performInitialSyncIfNeeded(isAuthenticated: Bool) async
    func performSync() async throws
    @discardableResult
    func clearLocalDatabase(force: Bool) async -> Bool
}

/// Port for reminder sync used by `CoordinateSyncUseCase` and session unlink flows.
protocol ReminderSyncCoordinating: AnyObject {
    func performSync() async throws
    @discardableResult
    func clearLocalDatabase(force: Bool) async -> Bool
}
