//
//  SettingsSyncRepositoryProtocol.swift
//  pagosApp
//
//  Repository protocol for settings sync operations
//  Clean Architecture - Domain Layer
//

import Foundation

/// Protocol for sync operations accessible from Settings
@MainActor
protocol SettingsSyncRepositoryProtocol {
    /// Perform full synchronization
    func performSync() async throws

    /// Clear local database
    func clearLocalDatabase(force: Bool) async -> Bool

    /// Update pending sync count
    func updatePendingSyncCount() async

    /// Current count of pending sync operations
    var pendingSyncCount: Int { get }

    /// Current sync error if any
    var syncError: PaymentSyncError? { get }
}
