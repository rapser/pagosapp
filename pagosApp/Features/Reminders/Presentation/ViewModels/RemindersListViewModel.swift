//
//  RemindersListViewModel.swift
//  pagosApp
//
//  ViewModel for Reminders list. Clean Architecture - Presentation.
//

import Foundation

@MainActor
@Observable
final class RemindersListViewModel: BaseViewModel {
    private var allReminders: [Reminder] = []

    private var filterSelection: ReminderFilterUI = .currentMonth
    var selectedFilter: ReminderFilterUI {
        get { filterSelection }
        set { filterSelection = newValue }
    }

    /// Reminders filtered by the selected segment
    var reminders: [Reminder] {
        let searchService = ReminderSearchService()
        let filter = ReminderSearchService.ReminderFilter.from(selectedFilter)
        return searchService.filter(allReminders, by: filter)
    }

    private let getAllRemindersUseCase: GetAllRemindersUseCase
    private let deleteReminderUseCase: DeleteReminderUseCase
    private let updateReminderUseCase: UpdateReminderUseCase
    private let rescheduleNotificationsUseCase: RescheduleReminderNotificationsUseCase?

    init(
        getAllRemindersUseCase: GetAllRemindersUseCase, 
        deleteReminderUseCase: DeleteReminderUseCase, 
        updateReminderUseCase: UpdateReminderUseCase,
        rescheduleNotificationsUseCase: RescheduleReminderNotificationsUseCase? = nil
    ) {
        self.getAllRemindersUseCase = getAllRemindersUseCase
        self.deleteReminderUseCase = deleteReminderUseCase
        self.updateReminderUseCase = updateReminderUseCase
        self.rescheduleNotificationsUseCase = rescheduleNotificationsUseCase
        super.init(category: "RemindersListViewModel")
    }

    func toggleCompletion(_ reminder: Reminder) async {
        let updated = Reminder(
            id: reminder.id,
            reminderType: reminder.reminderType,
            title: reminder.title,
            description: reminder.description,
            dueDate: reminder.dueDate,
            isCompleted: !reminder.isCompleted,
            notificationSettings: reminder.notificationSettings,
            syncStatus: reminder.syncStatus,
            lastSyncedAt: reminder.lastSyncedAt
        )
        switch await updateReminderUseCase.execute(updated) {
        case .success(let result):
            if let index = allReminders.firstIndex(where: { $0.id == result.id }) {
                allReminders[index] = result
            }
        case .failure(let error):
            logError(error)
            setError(reminderErrorMessage(for: error))
        }
    }

    func loadReminders() async {
        await withLoadingAndErrorHandling(
            operation: {
                let result = await self.getAllRemindersUseCase.execute()
                
                switch result {
                case .success(let list):
                    self.allReminders = list.sorted { $0.dueDate < $1.dueDate }
                    self.logDebug("Loaded \(list.count) reminders")
                    
                    ListNotificationBootstrap.runReminderRescheduleAfterFetch(
                        reminders: list,
                        useCase: self.rescheduleNotificationsUseCase
                    )
                    
                    return list
                case .failure(let error):
                    self.logError(error)
                    throw error
                }
            },
            onError: { error in
                if let reminderError = error as? ReminderError {
                    self.setError(self.reminderErrorMessage(for: reminderError))
                }
            }
        )
    }

    func deleteReminder(id: UUID) async {
        switch await deleteReminderUseCase.execute(id: id) {
        case .success:
            allReminders.removeAll { $0.id == id }
        case .failure(let error):
            logError(error)
            setError(reminderErrorMessage(for: error))
        }
    }

    private func reminderErrorMessage(for error: ReminderError) -> String {
        switch error {
        case .invalidTitle: return L10n.Reminders.Error.invalidTitle
        case .invalidDate: return L10n.Reminders.Error.invalidDate
        case .saveFailed(let s): return L10n.Reminders.Error.saveFailed(s)
        case .deleteFailed(let s): return L10n.Reminders.Error.deleteFailed(s)
        case .notFound: return L10n.Reminders.Error.notFound
        case .unknown(let s): return L10n.Reminders.Error.unknown(s)
        }
    }
}
