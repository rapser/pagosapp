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
final class AddReminderViewModel: LoadingStateViewModel {
    var reminderType: ReminderType = .other {
        didSet {
            // Update notification settings when type changes
            notificationSettings = NotificationSettings.recommended(for: reminderType)
        }
    }
    var title: String = ""
    var reminderDescription: String = ""
    var dueDate: Date = Date()
    var notificationSettings: NotificationSettings = NotificationSettings.recommended(for: .other)
    var didSave = false
    
    // LoadingStateViewModel conformance
    var isLoading = false
    var errorMessage: String?
    var showError = false

    private let createReminderUseCase: CreateReminderUseCase

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(createReminderUseCase: CreateReminderUseCase) {
        self.createReminderUseCase = createReminderUseCase
    }

    func save() async {
        let result = await withLoading {
            await createReminderUseCase.execute(
                type: reminderType,
                title: title,
                description: reminderDescription,
                dueDate: dueDate,
                notificationSettings: notificationSettings
            )
        }
        
        if let result = result {
            switch result {
            case .success:
                didSave = true
            case .failure(let error):
                setError(message(for: error))
            }
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
