//
//  SettingsViewModel.swift
//  pagosApp
//
//  ViewModel for Settings screen
//  Clean Architecture - Presentation Layer
//

import Foundation

@MainActor
@Observable
final class SettingsViewModel: BaseViewModel {
    // MARK: - Observable State

    var showingSyncError = false
    var syncErrorMessage = ""
    var pendingSyncCount: Int = 0
    var syncError: Error?
    /// Mensaje mostrado en el overlay de carga (sincronizando, cerrando sesión, etc.).
    var loadingMessage: String = ""

    // MARK: - Dependencies (Use Cases only - Clean Architecture)

    private let performSyncUseCase: PerformSyncUseCase
    private let clearLocalDatabaseUseCase: ClearLocalDatabaseUseCase
    private let updatePendingSyncCountUseCase: UpdatePendingSyncCountUseCase
    private let getSyncStatusUseCase: GetSyncStatusUseCase
    private let logoutUseCase: LogoutUseCase
    private let unlinkDeviceUseCase: UnlinkDeviceUseCase
    private let eventBus: EventBus

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
        super.init(category: "SettingsViewModel")

        setupEventListeners()
    }

    // MARK: - Event Listeners

    /// Setup event listeners for domain events
    private func setupEventListeners() {
        Task { @MainActor [weak self] in
            for await _ in self?.eventBus.subscribe(to: PaymentsSyncedEvent.self) ?? AsyncStream.never {
                await self?.updatePendingSyncCount()
            }
        }

        Task { @MainActor [weak self] in
            for await _ in self?.eventBus.subscribe(to: PaymentCreatedEvent.self) ?? AsyncStream.never {
                await self?.updatePendingSyncCount()
            }
        }

        Task { @MainActor [weak self] in
            for await _ in self?.eventBus.subscribe(to: PaymentUpdatedEvent.self) ?? AsyncStream.never {
                await self?.updatePendingSyncCount()
            }
        }

        Task { @MainActor [weak self] in
            for await _ in self?.eventBus.subscribe(to: PaymentDeletedEvent.self) ?? AsyncStream.never {
                await self?.updatePendingSyncCount()
            }
        }

        Task { @MainActor [weak self] in
            for await _ in self?.eventBus.subscribe(to: PaymentStatusToggledEvent.self) ?? AsyncStream.never {
                await self?.updatePendingSyncCount()
            }
        }
    }

    // MARK: - Sync Operations

    func handleSyncTapped() async {
        await performSync()
    }

    func performSync() async {
        loadingMessage = L10n.Settings.syncing
        isLoading = true
        defer { isLoading = false }

        do {
            try await performSyncUseCase.execute()
        } catch {
            logError(error, function: "performSync")
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

        let status = getSyncStatusUseCase.execute()
        pendingSyncCount = status.pendingSyncCount
        syncError = status.syncError
    }

    // MARK: - Database Operations

    func clearLocalDatabase() async -> Bool {
        loadingMessage = L10n.Settings.repairingDb
        isLoading = true
        defer { isLoading = false }

        let success = await clearLocalDatabaseUseCase.execute(force: true)

        if !success {
            logDebug("Database clear failed")
        }

        return success
    }

    // MARK: - Session Operations

    func logout() async {
        loadingMessage = L10n.Settings.loggingOut
        isLoading = true
        defer { isLoading = false }

        let result = await logoutUseCase.execute()

        if case .failure(let error) = result {
            logDebug("Logout failed: \(error.errorCode)")
            syncErrorMessage = L10n.Settings.logoutError
            showingSyncError = true
        }
    }

    func unlinkDevice() async {
        loadingMessage = L10n.Settings.unlinking
        isLoading = true
        defer { isLoading = false }

        let result = await unlinkDeviceUseCase.execute()

        if case .failure(let error) = result {
            logDebug("Unlink failed: \(error.errorCode)")
            syncErrorMessage = L10n.Settings.unlinkError
            showingSyncError = true
        }
    }
}
