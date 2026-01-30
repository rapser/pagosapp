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

    // MARK: - Dependencies (Use Cases only - Clean Architecture)

    private let performSyncUseCase: PerformSyncUseCase
    private let clearLocalDatabaseUseCase: ClearLocalDatabaseUseCase
    private let updatePendingSyncCountUseCase: UpdatePendingSyncCountUseCase
    private let getSyncStatusUseCase: GetSyncStatusUseCase
    private let logoutUseCase: LogoutUseCase
    private let unlinkDeviceUseCase: UnlinkDeviceUseCase
    private let eventBus: EventBus

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "SettingsViewModel")

    // MARK: - Initialization

    init(
        performSyncUseCase: PerformSyncUseCase,
        clearLocalDatabaseUseCase: ClearLocalDatabaseUseCase,
        updatePendingSyncCountUseCase: UpdatePendingSyncCountUseCase,
        getSyncStatusUseCase: GetSyncStatusUseCase,
        logoutUseCase: LogoutUseCase,
        unlinkDeviceUseCase: UnlinkDeviceUseCase,
        eventBus: EventBus
    ) {
        self.performSyncUseCase = performSyncUseCase
        self.clearLocalDatabaseUseCase = clearLocalDatabaseUseCase
        self.updatePendingSyncCountUseCase = updatePendingSyncCountUseCase
        self.getSyncStatusUseCase = getSyncStatusUseCase
        self.logoutUseCase = logoutUseCase
        self.unlinkDeviceUseCase = unlinkDeviceUseCase
        self.eventBus = eventBus

        // Note: Initial data fetch moved to .task in View (iOS 18 best practice)

        // Setup event listeners
        setupEventListeners()
    }

    // MARK: - Event Listeners

    /// Setup event listeners for domain events
    private func setupEventListeners() {
        // Listen to PaymentsSyncedEvent
        Task { @MainActor in
            for await _ in eventBus.subscribe(to: PaymentsSyncedEvent.self) {
                logger.debug("📢 Received PaymentsSyncedEvent, updating pending sync count")
                await updatePendingSyncCount()
            }
        }

        // Listen to payment changes for sync count updates
        Task { @MainActor in
            for await _ in eventBus.subscribe(to: PaymentCreatedEvent.self) {
                await updatePendingSyncCount()
            }
        }

        Task { @MainActor in
            for await _ in eventBus.subscribe(to: PaymentUpdatedEvent.self) {
                await updatePendingSyncCount()
            }
        }

        Task { @MainActor in
            for await _ in eventBus.subscribe(to: PaymentDeletedEvent.self) {
                await updatePendingSyncCount()
            }
        }

        Task { @MainActor in
            for await _ in eventBus.subscribe(to: PaymentStatusToggledEvent.self) {
                await updatePendingSyncCount()
            }
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

        // Get sync status through UseCase (Clean Architecture)
        let status = getSyncStatusUseCase.execute()
        pendingSyncCount = status.pendingSyncCount
        syncError = status.syncError
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
        let result = await logoutUseCase.execute()

        if case .failure(let error) = result {
            logger.error("❌ Logout failed: \(error.errorCode)")
            syncErrorMessage = "Error al cerrar sesión"
            showingSyncError = true
        }
    }

    func unlinkDevice() async {
        isLoading = true
        defer { isLoading = false }

        logger.info("🔓 Unlinking device")
        let result = await unlinkDeviceUseCase.execute()

        if case .failure(let error) = result {
            logger.error("❌ Unlink device failed: \(error.errorCode)")
            syncErrorMessage = "Error al desvincular dispositivo"
            showingSyncError = true
        }
    }
}
