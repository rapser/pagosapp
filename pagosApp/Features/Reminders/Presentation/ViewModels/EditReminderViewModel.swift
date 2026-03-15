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
    var reminderType: ReminderType {
        didSet {
            // Only update notification settings if they haven't been customized
            if notificationSettings == NotificationSettings.recommended(for: oldValue) {
                notificationSettings = NotificationSettings.recommended(for: reminderType)
            }
        }
    }
    var title: String
    var reminderDescription: String
    var dueDate: Date
    var isCompleted: Bool
    var notificationSettings: NotificationSettings
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
        self.reminderDescription = reminder.description
        self.dueDate = reminder.dueDate
        self.isCompleted = reminder.isCompleted
        self.notificationSettings = reminder.notificationSettings
        self.updateReminderUseCase = updateReminderUseCase
    }

    func save() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        let newStatus: ReminderSyncStatus = reminder.syncStatus == .synced ? .modified : reminder.syncStatus
        let updated = Reminder(
            id: reminder.id,
            reminderType: reminderType,
            title: title,
            description: reminderDescription,
            dueDate: dueDate,
            isCompleted: isCompleted,
            notificationSettings: notificationSettings,
            syncStatus: newStatus,
            lastSyncedAt: reminder.lastSyncedAt
        )
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
