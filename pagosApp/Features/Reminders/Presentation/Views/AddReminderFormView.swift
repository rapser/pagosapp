//
//  AddReminderFormView.swift
//  pagosApp
//
//  Formulario de nuevo recordatorio: tipo, título, descripción, fecha.
//  Clean Architecture - Presentation (Reminders feature).
//

import SwiftUI

struct AddReminderFormView: View {
    @Bindable var viewModel: AddReminderViewModel
    let dismiss: DismissAction

    var body: some View {
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
            Section(L10n.Reminders.descriptionLabel) {
                TextField(L10n.Reminders.descriptionPlaceholder, text: $viewModel.reminderDescription, axis: .vertical)
                    .lineLimit(3...6)
            }
            Section(L10n.Reminders.dueDateLabel) {
                DatePicker(L10n.Reminders.dueDateLabel, selection: $viewModel.dueDate, displayedComponents: .date)
            }
            
            NotificationSettingsView(
                notificationSettings: $viewModel.notificationSettings,
                reminderType: viewModel.reminderType
            )
        }
        .navigationTitle(L10n.Reminders.Add.title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.General.cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.General.save) {
                    Task {
                        await viewModel.save()
                        if viewModel.didSave { dismiss() }
                    }
                }
                .disabled(!viewModel.isValid)
            }
        }
        .disabled(viewModel.isLoading)
        .overlay {
            if viewModel.isLoading {
                ProgressView(L10n.Reminders.Edit.saving)
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
        }
        .errorAlert(
            isPresented: $viewModel.showError,
            message: viewModel.errorMessage,
            title: L10n.General.error
        )
    }
}
