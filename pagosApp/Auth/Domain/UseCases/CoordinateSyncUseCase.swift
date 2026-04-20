//
//  CoordinateSyncUseCase.swift
//  pagosApp
//
//  Use Case to coordinate synchronization across features.
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case to coordinate sync operations across different features
protocol CoordinateSyncUseCaseProtocol {
    func triggerInitialSync() async
    func handlePostLoginSync() async
}

/// Implementation of sync coordination
final class CoordinateSyncUseCase: CoordinateSyncUseCaseProtocol {
    private static let logCategory = "CoordinateSyncUseCase"

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

    func triggerInitialSync() async {
        log.info("🔄 Starting initial sync coordination", category: Self.logCategory)

        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in
                await self.paymentSync.performInitialSyncIfNeeded(isAuthenticated: true)
            }

            group.addTask { @MainActor in
                do {
                    try await self.reminderSync.performSync()
                } catch {
                    self.log.error(
                        "⚠️ Initial reminder sync failed: \(error.localizedDescription)",
                        category: Self.logCategory
                    )
                }
            }
        }
    }

    func handlePostLoginSync() async {
        log.info("🔄 Starting post-login sync coordination", category: Self.logCategory)

        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in
                do {
                    try await self.paymentSync.performSync()
                } catch {
                    self.log.error(
                        "⚠️ Post-login payment sync failed: \(error.localizedDescription)",
                        category: Self.logCategory
                    )
                }
            }

            group.addTask { @MainActor in
                do {
                    try await self.reminderSync.performSync()
                } catch {
                    self.log.error(
                        "⚠️ Post-login reminder sync failed: \(error.localizedDescription)",
                        category: Self.logCategory
                    )
                }
            }
        }
    }
}
