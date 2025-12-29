//
//  SettingsDependencyContainer.swift
//  pagosApp
//
//  Dependency Injection Container for Settings module
//  Clean Architecture - DI Layer
//

import Foundation

/// Dependency injection container for Settings module
@MainActor
final class SettingsDependencyContainer {
    // MARK: - External Dependencies

    private let paymentSyncCoordinator: PaymentSyncCoordinator
    private let authDependencyContainer: AuthDependencyContainer
    private let sessionCoordinator: SessionCoordinator

    init(
        paymentSyncCoordinator: PaymentSyncCoordinator,
        authDependencyContainer: AuthDependencyContainer,
        sessionCoordinator: SessionCoordinator
    ) {
        self.paymentSyncCoordinator = paymentSyncCoordinator
        self.authDependencyContainer = authDependencyContainer
        self.sessionCoordinator = sessionCoordinator
    }

    // MARK: - Repositories

    func makeSettingsSyncRepository() -> SettingsSyncRepositoryProtocol {
        SettingsSyncRepositoryImpl(
            paymentSyncCoordinator: paymentSyncCoordinator
        )
    }

    // MARK: - Use Cases

    func makePerformSyncUseCase() -> PerformSyncUseCase {
        PerformSyncUseCase(
            syncRepository: makeSettingsSyncRepository()
        )
    }

    func makeClearLocalDatabaseUseCase() -> ClearLocalDatabaseUseCase {
        ClearLocalDatabaseUseCase(
            syncRepository: makeSettingsSyncRepository()
        )
    }

    func makeUpdatePendingSyncCountUseCase() -> UpdatePendingSyncCountUseCase {
        UpdatePendingSyncCountUseCase(
            syncRepository: makeSettingsSyncRepository()
        )
    }

    // MARK: - ViewModels

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            performSyncUseCase: makePerformSyncUseCase(),
            clearLocalDatabaseUseCase: makeClearLocalDatabaseUseCase(),
            updatePendingSyncCountUseCase: makeUpdatePendingSyncCountUseCase(),
            syncRepository: makeSettingsSyncRepository(),
            sessionCoordinator: sessionCoordinator
        )
    }
}
