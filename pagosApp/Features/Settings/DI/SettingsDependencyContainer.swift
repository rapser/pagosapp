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
    private let reminderSyncCoordinator: ReminderSyncCoordinator
    private let authDependencyContainer: AuthDependencyContainer
    private let userProfileDependencyContainer: UserProfileDependencyContainer
    private let eventBus: EventBus
    private let notificationDataSource: NotificationDataSource
    private let reminderDependencyContainer: ReminderDependencyContainer

    // Single repository instance shared across all use cases
    private lazy var sharedSettingsSyncRepository: SettingsSyncRepositoryProtocol = SettingsSyncRepositoryImpl(
        paymentSyncCoordinator: paymentSyncCoordinator,
        reminderSyncCoordinator: reminderSyncCoordinator
    )

    init(
        paymentSyncCoordinator: PaymentSyncCoordinator,
        reminderSyncCoordinator: ReminderSyncCoordinator,
        authDependencyContainer: AuthDependencyContainer,
        userProfileDependencyContainer: UserProfileDependencyContainer,
        eventBus: EventBus,
        notificationDataSource: NotificationDataSource,
        reminderDependencyContainer: ReminderDependencyContainer
    ) {
        self.paymentSyncCoordinator = paymentSyncCoordinator
        self.reminderSyncCoordinator = reminderSyncCoordinator
        self.authDependencyContainer = authDependencyContainer
        self.userProfileDependencyContainer = userProfileDependencyContainer
        self.eventBus = eventBus
        self.notificationDataSource = notificationDataSource
        self.reminderDependencyContainer = reminderDependencyContainer
    }

    // MARK: - Repositories

    func makeSettingsSyncRepository() -> SettingsSyncRepositoryProtocol {
        sharedSettingsSyncRepository
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
    
    func makeNotificationDebugView() -> NotificationDebugView {
        let viewModel = makeNotificationDebugViewModel()
        return NotificationDebugView(viewModel: viewModel)
    }
    
    func makeNotificationDebugViewModel() -> NotificationDebugViewModel {
        NotificationDebugViewModel(
            notificationDataSource: notificationDataSource,
            getAllRemindersUseCase: reminderDependencyContainer.makeGetAllRemindersUseCase(),
            rescheduleNotificationsUseCase: reminderDependencyContainer.makeRescheduleReminderNotificationsUseCase()
        )
    }
}
