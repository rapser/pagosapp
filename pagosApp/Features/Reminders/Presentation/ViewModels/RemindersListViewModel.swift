//
//  RemindersListViewModel.swift
//  pagosApp
//
//  ViewModel for Reminders list. Clean Architecture - Presentation.
//

import Foundation
import Observation

@MainActor
@Observable
final class RemindersListViewModel {
    var reminders: [Reminder] = []
    var isLoading = false
    var errorMessage: String?
    var showError = false

    private let getAllRemindersUseCase: GetAllRemindersUseCase
    private let deleteReminderUseCase: DeleteReminderUseCase

    init(getAllRemindersUseCase: GetAllRemindersUseCase, deleteReminderUseCase: DeleteReminderUseCase) {
        self.getAllRemindersUseCase = getAllRemindersUseCase
        self.deleteReminderUseCase = deleteReminderUseCase
    }

    func loadReminders() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        switch await getAllRemindersUseCase.execute() {
        case .success(let list):
            reminders = list.sorted { $0.dueDate < $1.dueDate }
        case .failure(let error):
            errorMessage = message(for: error)
            showError = true
        }
    }

    func deleteReminder(id: UUID) async {
        switch await deleteReminderUseCase.execute(id: id) {
        case .success:
            reminders.removeAll { $0.id == id }
        case .failure(let error):
            errorMessage = message(for: error)
            showError = true
        }
    }

    private func message(for error: ReminderError) -> String {
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
