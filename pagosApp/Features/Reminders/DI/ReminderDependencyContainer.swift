//
//  ReminderDependencyContainer.swift
//  pagosApp
//
//  Dependency injection container for Reminders feature.
//  Clean Architecture - DI Layer
//

import Foundation
import SwiftData
import Supabase

@MainActor
final class ReminderDependencyContainer {
    private let modelContext: ModelContext
    private let notificationDataSource: NotificationDataSource
    private let supabaseClient: SupabaseClient
    private let log: DomainLogWriter

    private lazy var localDataSource: ReminderLocalDataSource = {
        ReminderSwiftDataDataSource(modelContext: modelContext, log: log)
    }()

    private lazy var remoteDataSource: ReminderRemoteDataSource = {
        ReminderSupabaseDataSource(client: supabaseClient)
    }()

    private lazy var remoteMapper: ReminderRemoteDTOMapping = {
        ReminderRemoteDTOMapper()
    }()

    private lazy var repository: ReminderRepositoryProtocol = {
        ReminderRepositoryImpl(
            localDataSource: localDataSource,
            notificationDataSource: notificationDataSource,
            log: log
        )
    }()

    private lazy var syncRepository: ReminderSyncRepositoryProtocol = {
        ReminderSyncRepositoryImpl(
            remoteDataSource: remoteDataSource,
            localDataSource: localDataSource,
            supabaseClient: supabaseClient,
            remoteMapper: remoteMapper
        )
    }()

    init(
        modelContext: ModelContext,
        notificationDataSource: NotificationDataSource,
        supabaseClient: SupabaseClient,
        log: DomainLogWriter
    ) {
        self.modelContext = modelContext
        self.notificationDataSource = notificationDataSource
        self.supabaseClient = supabaseClient
        self.log = log
    }

    func makeCreateReminderUseCase() -> CreateReminderUseCase {
        CreateReminderUseCase(repository: repository)
    }

    func makeRescheduleReminderNotificationsUseCase() -> RescheduleReminderNotificationsUseCase {
        RescheduleReminderNotificationsUseCase(
            notificationDataSource: notificationDataSource,
            log: log
        )
    }

    func makeGetAllRemindersUseCase() -> GetAllRemindersUseCase {
        GetAllRemindersUseCase(repository: repository)
    }

    func makeUpdateReminderUseCase() -> UpdateReminderUseCase {
        UpdateReminderUseCase(repository: repository)
    }

    func makeDeleteReminderUseCase() -> DeleteReminderUseCase {
        DeleteReminderUseCase(repository: repository)
    }

    func makeRemindersListViewModel() -> RemindersListViewModel {
        RemindersListViewModel(
            getAllRemindersUseCase: makeGetAllRemindersUseCase(),
            deleteReminderUseCase: makeDeleteReminderUseCase(),
            updateReminderUseCase: makeUpdateReminderUseCase(),
            rescheduleNotificationsUseCase: makeRescheduleReminderNotificationsUseCase()
        )
    }

    func makeAddReminderViewModel() -> AddReminderViewModel {
        AddReminderViewModel(createReminderUseCase: makeCreateReminderUseCase())
    }

    func makeEditReminderViewModel(reminder: Reminder) -> EditReminderViewModel {
        EditReminderViewModel(
            reminder: reminder,
            updateReminderUseCase: makeUpdateReminderUseCase()
        )
    }

    // MARK: - Sync

    func makeReminderSyncCoordinator() -> ReminderSyncCoordinator {
        ReminderSyncCoordinator(
            syncRemindersUseCase: SyncRemindersUseCase(
                uploadUseCase: UploadReminderChangesUseCase(syncRepository: syncRepository, log: log),
                downloadUseCase: DownloadReminderChangesUseCase(
                    syncRepository: syncRepository,
                    localDataSource: localDataSource,
                    log: log
                )
            ),
            getPendingSyncCountUseCase: GetPendingReminderSyncCountUseCase(syncRepository: syncRepository),
            syncRepository: syncRepository,
            localDataSource: localDataSource,
            rescheduleNotificationsUseCase: makeRescheduleReminderNotificationsUseCase(),
            log: log
        )
    }
}
