//
//  SyncCoordinationPorts.swift
//  pagosApp
//
//  Domain-facing ports for cross-feature sync coordination (no concrete coordinator types).
//

import Foundation

/// Port for payment sync entry points used by `CoordinateSyncUseCase`.
protocol PaymentSyncCoordinating: AnyObject {
    func performInitialSyncIfNeeded(isAuthenticated: Bool) async
    func performSync() async throws
}

/// Port for reminder sync used by `CoordinateSyncUseCase`.
protocol ReminderSyncCoordinating: AnyObject {
    func performSync() async throws
}
