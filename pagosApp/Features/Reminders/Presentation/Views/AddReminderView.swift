//
//  AddReminderView.swift
//  pagosApp
//
//  Form to add a new reminder. Clean Architecture - Presentation.
//

import SwiftUI

struct AddReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: AddReminderViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.Reminders.typeLabel) {
                    Picker(L10n.Reminders.typeLabel, selection: $viewModel.reminderType) {
                        ForEach(ReminderType.allCases, id: \.self) { type in
                            Text(L10n.Reminders.typeDisplayName(type)).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section(L10n.Reminders.titleLabel) {
                    TextField(L10n.Reminders.titleLabel, text: $viewModel.title)
                }
                Section(L10n.Reminders.dueDateLabel) {
                    DatePicker(L10n.Reminders.dueDateLabel, selection: $viewModel.dueDate, displayedComponents: .date)
                }
            }
            .navigationTitle(L10n.Reminders.addTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.General.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.General.save) {
                        Task {
                            await viewModel.save()
                            if viewModel.didSave { dismiss() }
                        }
                    }
                    .disabled(viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSaving)
                }
            }
            .overlay {
                if viewModel.isSaving {
                    ProgressView()
                }
            }
            .errorAlert(
                isPresented: $viewModel.showError,
                message: viewModel.errorMessage,
                title: L10n.General.error
            )
        }
    }
}
