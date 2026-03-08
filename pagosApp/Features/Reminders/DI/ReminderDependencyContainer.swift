//
//  ReminderDependencyContainer.swift
//  pagosApp
//
//  Dependency injection container for Reminders feature.
//  Clean Architecture - DI Layer
//

import Foundation
import SwiftData

@MainActor
final class ReminderDependencyContainer {
    private let modelContext: ModelContext
    private let notificationDataSource: NotificationDataSource

    private lazy var localDataSource: ReminderLocalDataSource = {
        ReminderSwiftDataDataSource(modelContext: modelContext)
    }()

    private lazy var repository: ReminderRepositoryProtocol = {
        ReminderRepositoryImpl(
            localDataSource: localDataSource,
            notificationDataSource: notificationDataSource
        )
    }()

    init(modelContext: ModelContext, notificationDataSource: NotificationDataSource) {
        self.modelContext = modelContext
        self.notificationDataSource = notificationDataSource
    }

    func makeCreateReminderUseCase() -> CreateReminderUseCase {
        CreateReminderUseCase(repository: repository)
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
            deleteReminderUseCase: makeDeleteReminderUseCase()
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
}
