//
//  AddReminderViewModel.swift
//  pagosApp
//
//  ViewModel for Add Reminder screen. Clean Architecture - Presentation.
//

import Foundation
import Observation

@MainActor
@Observable
final class AddReminderViewModel {
    var reminderType: ReminderType = .other
    var title: String = ""
    var dueDate: Date = Date()
    var isSaving = false
    var errorMessage: String?
    var showError = false
    var didSave = false

    private let createReminderUseCase: CreateReminderUseCase

    init(createReminderUseCase: CreateReminderUseCase) {
        self.createReminderUseCase = createReminderUseCase
    }

    func save() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        switch await createReminderUseCase.execute(type: reminderType, title: title, dueDate: dueDate) {
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
