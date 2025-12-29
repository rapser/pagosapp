//
//  SettingsViewModel.swift
//  pagosApp
//
//  ViewModel for Settings screen
//  Clean Architecture - Presentation Layer
//

import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class SettingsViewModel {
    // MARK: - Observable State

    var showingSyncError = false
    var syncErrorMessage = ""
    var pendingSyncCount: Int = 0
    var syncError: PaymentSyncError? = nil
    var isLoading = false

    // MARK: - Dependencies

    private let performSyncUseCase: PerformSyncUseCase
    private let clearLocalDatabaseUseCase: ClearLocalDatabaseUseCase
    private let updatePendingSyncCountUseCase: UpdatePendingSyncCountUseCase
    private let syncRepository: SettingsSyncRepositoryProtocol
    private let sessionCoordinator: SessionCoordinator

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "SettingsViewModel")

    // MARK: - Initialization

    init(
        performSyncUseCase: PerformSyncUseCase,
        clearLocalDatabaseUseCase: ClearLocalDatabaseUseCase,
        updatePendingSyncCountUseCase: UpdatePendingSyncCountUseCase,
        syncRepository: SettingsSyncRepositoryProtocol,
        sessionCoordinator: SessionCoordinator
    ) {
        self.performSyncUseCase = performSyncUseCase
        self.clearLocalDatabaseUseCase = clearLocalDatabaseUseCase
        self.updatePendingSyncCountUseCase = updatePendingSyncCountUseCase
        self.syncRepository = syncRepository
        self.sessionCoordinator = sessionCoordinator

        Task {
            await updatePendingSyncCount()
        }
    }

    // MARK: - Sync Operations

    func handleSyncTapped() async {
        await performSync()
    }

    func performSync() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await performSyncUseCase.execute()
            logger.info("✅ Sync completed successfully")
        } catch {
            logger.error("❌ Sync failed: \(error.localizedDescription)")
            syncErrorMessage = error.localizedDescription
            showingSyncError = true
        }
    }

    func clearSyncError() async {
        syncError = nil
        await performSync()
    }

    func updatePendingSyncCount() async {
        await updatePendingSyncCountUseCase.execute()
        pendingSyncCount = syncRepository.pendingSyncCount
        syncError = syncRepository.syncError
    }

    // MARK: - Database Operations

    func clearLocalDatabase() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        logger.info("🗑️ Clearing local database")
        let success = await clearLocalDatabaseUseCase.execute(force: true)

        if success {
            logger.info("✅ Local database cleared successfully")
        } else {
            logger.error("❌ Failed to clear local database")
        }

        return success
    }

    // MARK: - Session Operations

    func logout() async {
        isLoading = true
        defer { isLoading = false }

        logger.info("🚪 Logging out")
        await sessionCoordinator.logout()
    }

    func unlinkDevice() async {
        isLoading = true
        defer { isLoading = false }

        logger.info("🔓 Unlinking device")
        await sessionCoordinator.unlinkDevice()
    }
}
