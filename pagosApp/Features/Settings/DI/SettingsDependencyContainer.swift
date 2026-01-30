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
    private let userProfileDependencyContainer: UserProfileDependencyContainer
    private let eventBus: EventBus

    init(
        paymentSyncCoordinator: PaymentSyncCoordinator,
        authDependencyContainer: AuthDependencyContainer,
        userProfileDependencyContainer: UserProfileDependencyContainer,
        eventBus: EventBus
    ) {
        self.paymentSyncCoordinator = paymentSyncCoordinator
        self.authDependencyContainer = authDependencyContainer
        self.userProfileDependencyContainer = userProfileDependencyContainer
        self.eventBus = eventBus
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

    func makeGetSyncStatusUseCase() -> GetSyncStatusUseCase {
        GetSyncStatusUseCase(
            syncRepository: makeSettingsSyncRepository()
        )
    }

    // MARK: - ViewModels

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            performSyncUseCase: makePerformSyncUseCase(),
            clearLocalDatabaseUseCase: makeClearLocalDatabaseUseCase(),
            updatePendingSyncCountUseCase: makeUpdatePendingSyncCountUseCase(),
            getSyncStatusUseCase: makeGetSyncStatusUseCase(),
            logoutUseCase: authDependencyContainer.makeLogoutUseCase(),
            unlinkDeviceUseCase: authDependencyContainer.makeUnlinkDeviceUseCase(
                clearLocalDatabaseUseCase: makeClearLocalDatabaseUseCase(),
                deleteLocalProfileUseCase: userProfileDependencyContainer.makeDeleteLocalProfileUseCase()
            ),
            eventBus: eventBus
        )
    }
}
