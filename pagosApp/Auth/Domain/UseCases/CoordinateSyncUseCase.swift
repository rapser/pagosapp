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

    private let paymentSyncCoordinator: PaymentSyncCoordinator
    private let reminderSyncCoordinator: ReminderSyncCoordinator
    private let log: DomainLogWriter

    init(
        paymentSyncCoordinator: PaymentSyncCoordinator,
        reminderSyncCoordinator: ReminderSyncCoordinator,
        log: DomainLogWriter
    ) {
        self.paymentSyncCoordinator = paymentSyncCoordinator
        self.reminderSyncCoordinator = reminderSyncCoordinator
        self.log = log
    }

    func triggerInitialSync() async {
        log.info("🔄 Starting initial sync coordination", category: Self.logCategory)

        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in
                await self.paymentSyncCoordinator.performInitialSyncIfNeeded(isAuthenticated: true)
            }

            group.addTask { @MainActor in
                do {
                    try await self.reminderSyncCoordinator.performSync()
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
                    try await self.paymentSyncCoordinator.performSync()
                } catch {
                    self.log.error(
                        "⚠️ Post-login payment sync failed: \(error.localizedDescription)",
                        category: Self.logCategory
                    )
                }
            }

            group.addTask { @MainActor in
                do {
                    try await self.reminderSyncCoordinator.performSync()
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
