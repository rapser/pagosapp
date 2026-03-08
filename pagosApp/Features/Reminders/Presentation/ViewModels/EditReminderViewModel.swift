//
//  EditReminderViewModel.swift
//  pagosApp
//
//  ViewModel for Edit Reminder screen. Clean Architecture - Presentation.
//

import Foundation
import Observation

@MainActor
@Observable
final class EditReminderViewModel {
    var reminderType: ReminderType
    var title: String
    var dueDate: Date
    var isSaving = false
    var errorMessage: String?
    var showError = false
    var didSave = false

    let reminder: Reminder
    private let updateReminderUseCase: UpdateReminderUseCase

    init(reminder: Reminder, updateReminderUseCase: UpdateReminderUseCase) {
        self.reminder = reminder
        self.reminderType = reminder.reminderType
        self.title = reminder.title
        self.dueDate = reminder.dueDate
        self.updateReminderUseCase = updateReminderUseCase
    }

    func save() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        let updated = Reminder(id: reminder.id, reminderType: reminderType, title: title, dueDate: dueDate)
        switch await updateReminderUseCase.execute(updated) {
        case .success:
            didSave = true
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
