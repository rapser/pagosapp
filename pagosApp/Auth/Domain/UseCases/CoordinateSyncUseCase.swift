//
//  CoordinateSyncUseCase.swift
//  pagosApp
//
//  Use Case to coordinate synchronization across features.
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

/// Use case to coordinate sync operations across different features
protocol CoordinateSyncUseCaseProtocol {
    func triggerInitialSync() async
    func handlePostLoginSync() async
}

/// Implementation of sync coordination
final class CoordinateSyncUseCase: CoordinateSyncUseCaseProtocol {
    
    private let paymentSyncCoordinator: PaymentSyncCoordinator
    private let reminderSyncCoordinator: ReminderSyncCoordinator
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "CoordinateSyncUseCase")
    
    init(
        paymentSyncCoordinator: PaymentSyncCoordinator,
        reminderSyncCoordinator: ReminderSyncCoordinator
    ) {
        self.paymentSyncCoordinator = paymentSyncCoordinator
        self.reminderSyncCoordinator = reminderSyncCoordinator
    }
    
    func triggerInitialSync() async {
        logger.info("🔄 Starting initial sync coordination")
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                await self?.paymentSyncCoordinator.performInitialSyncIfNeeded(isAuthenticated: true)
            }
            
            group.addTask { [weak self] in 
                do {
                    try await self?.reminderSyncCoordinator.performSync()
                } catch {
                    // Log error but don't fail the entire sync
                    self?.logger.error("⚠️ Initial reminder sync failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func handlePostLoginSync() async {
        logger.info("🔄 Starting post-login sync coordination")
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                do {
                    try await self?.paymentSyncCoordinator.performSync()
                } catch {
                    // Log error but don't fail the entire sync
                    self?.logger.error("⚠️ Post-login payment sync failed: \(error.localizedDescription)")
                }
            }
            
            group.addTask { [weak self] in
                do {
                    try await self?.reminderSyncCoordinator.performSync()
                } catch {
                    // Log error but don't fail the entire sync
                    self?.logger.error("⚠️ Post-login reminder sync failed: \(error.localizedDescription)")
                }
            }
        }
    }
}
