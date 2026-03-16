//
//  AppSyncManager.swift
//  pagosApp
//
//  Facade that aggregates sync state from PaymentSyncCoordinator and ReminderSyncCoordinator.
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
    private let paymentSyncCoordinator: PaymentSyncCoordinator
    private let reminderSyncCoordinator: ReminderSyncCoordinator

    init(
        paymentSyncCoordinator: PaymentSyncCoordinator,
        reminderSyncCoordinator: ReminderSyncCoordinator
    ) {
        self.paymentSyncCoordinator = paymentSyncCoordinator
        self.reminderSyncCoordinator = reminderSyncCoordinator
    }

    // MARK: - Aggregated State

    var isSyncing: Bool {
        paymentSyncCoordinator.isSyncing || reminderSyncCoordinator.isSyncing
    }

    var pendingSyncCount: Int {
        paymentSyncCoordinator.pendingSyncCount + reminderSyncCoordinator.pendingSyncCount
    }

    var lastSyncDate: Date? {
        let payment = paymentSyncCoordinator.lastSyncDate
        let reminder = reminderSyncCoordinator.lastSyncDate
        switch (payment, reminder) {
        case let (p?, r?): return max(p, r)
        case (let p?, nil): return p
        case (nil, let r?): return r
        case (nil, nil): return nil
        }
    }

    var syncError: Error? {
        paymentSyncCoordinator.syncError ?? reminderSyncCoordinator.syncError
    }
}
