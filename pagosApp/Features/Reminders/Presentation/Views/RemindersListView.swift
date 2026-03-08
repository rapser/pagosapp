//
//  RemindersListView.swift
//  pagosApp
//
//  Main list view for reminders. Clean Architecture - Presentation.
//

import SwiftUI

struct RemindersListView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var viewModel: RemindersListViewModel?
    @State private var showingAddSheet = false
    @State private var reminderToEdit: Reminder?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    remindersContent(viewModel: viewModel)
                } else {
                    ProgressView(L10n.General.loading)
                }
            }
            .navigationTitle(L10n.Reminders.listTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    AddReminderButton(action: { showingAddSheet = true })
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddReminderView()
                    .onDisappear {
                        Task { await viewModel?.loadReminders() }
                    }
            }
            .sheet(item: $reminderToEdit) { reminder in
                EditReminderView(viewModel: dependencies.reminderDependencyContainer.makeEditReminderViewModel(reminder: reminder))
                    .onDisappear {
                        Task { await viewModel?.loadReminders() }
                    }
            }
            .task {
                guard viewModel == nil else { return }
                viewModel = dependencies.reminderDependencyContainer.makeRemindersListViewModel()
                await viewModel?.loadReminders()
            }
            .errorAlert(
                isPresented: Binding(get: { viewModel?.showError ?? false }, set: { viewModel?.showError = $0 }),
                message: viewModel?.errorMessage,
                title: L10n.General.error
            )
        }
    }

    @ViewBuilder
    private func remindersContent(viewModel: RemindersListViewModel) -> some View {
        if viewModel.reminders.isEmpty {
            GenericEmptyStateView(
                icon: "bell.badge",
                title: L10n.Reminders.emptyTitle,
                description: L10n.Reminders.emptyDescription
            )
        } else {
            List {
                ForEach(viewModel.reminders, id: \.id) { reminder in
                    ReminderRowView(reminder: reminder)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            reminderToEdit = reminder
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteReminder(id: reminder.id)
                                }
                            } label: {
                                Label(L10n.General.delete, systemImage: "trash")
                            }
                        }
                }
            }
        }
    }
}

// MARK: - Row
private struct ReminderRowView: View {
    let reminder: Reminder
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(reminder.title)
                .font(.headline)
            if !reminder.description.isEmpty {
                Text(reminder.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text(L10n.Reminders.typeDisplayName(reminder.reminderType))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(Self.dateFormatter.string(from: reminder.dueDate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Button (mismo estilo que en Pagos)
private struct AddReminderButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .foregroundColor(primaryColor)
        }
    }

    private var primaryColor: Color {
        Color(uiColor: UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return .white
            } else {
                return UIColor(named: "AppPrimary") ?? .systemBlue
            }
        })
    }
}

// MARK: - Identifiable for sheet(item:)
extension Reminder: Identifiable {}
