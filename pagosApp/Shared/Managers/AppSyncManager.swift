//
//  AppSyncManager.swift
//  pagosApp
//
//  Facade that aggregates sync state from payment and reminder sync ports (coordinators conform).
//  Single @Observable/@Environment injection point for sync state in Views.
//  Clean Architecture - Shared Infrastructure
//

import Foundation
import Observation

/// Aggregates observable sync state from both Payment and Reminder sync coordinators.
/// Views use this single object instead of depending on two separate coordinators.
@MainActor
@Observable
final class AppSyncManager {
    private let paymentSync: PaymentSyncCoordinating
    private let reminderSync: ReminderSyncCoordinating

    init(
        paymentSync: PaymentSyncCoordinating,
        reminderSync: ReminderSyncCoordinating
    ) {
        self.paymentSync = paymentSync
        self.reminderSync = reminderSync
    }

    // MARK: - Aggregated State

    var isSyncing: Bool {
        paymentSync.isSyncing || reminderSync.isSyncing
    }

    var pendingSyncCount: Int {
        paymentSync.pendingSyncCount + reminderSync.pendingSyncCount
    }

    var lastSyncDate: Date? {
        let payment = paymentSync.lastSyncDate
        let reminder = reminderSync.lastSyncDate
        switch (payment, reminder) {
        case let (p?, r?): return max(p, r)
        case (let p?, nil): return p
        case (nil, let r?): return r
        case (nil, nil): return nil
        }
    }

    var syncError: Error? {
        paymentSync.syncError ?? reminderSync.syncError
    }
}
