//
//  RemindersListView.swift
//  pagosApp
//
//  Main list view for reminders. Clean Architecture - Presentation.
//

import SwiftUI

struct RemindersListView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var showingAddSheet = false
    @State private var viewModel: RemindersListViewModel?

    var body: some View {
        RemindersListContentWrapper(showingAddSheet: $showingAddSheet)
            .environment(dependencies)
    }
}

// MARK: - Content Wrapper (handles initialization)

private struct RemindersListContentWrapper: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var viewModel: RemindersListViewModel?
    @Binding var showingAddSheet: Bool

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    RemindersListContent(viewModel: viewModel)
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
        }
        .task {
            guard viewModel == nil else { return }
            viewModel = dependencies.reminderDependencyContainer.makeRemindersListViewModel()
            await viewModel?.loadReminders()
        }
        .sheet(isPresented: $showingAddSheet) {
            AddReminderView()
        }
        .onChange(of: showingAddSheet) { _, isPresented in
            if !isPresented {
                Task { await viewModel?.loadReminders() }
            }
        }
        .errorAlert(
            isPresented: Binding(get: { viewModel?.showError ?? false }, set: { viewModel?.showError = $0 }),
            message: viewModel?.errorMessage,
            title: L10n.General.error
        )
    }
}

// MARK: - Main Content (with ViewModel)

private struct RemindersListContent: View {
    @Bindable var viewModel: RemindersListViewModel
    @Environment(AppDependencies.self) private var dependencies

    var body: some View {
        if viewModel.isLoading {
            ProgressView(L10n.General.loading)
        } else if viewModel.reminders.isEmpty {
            GenericEmptyStateView(
                icon: "bell.badge",
                title: L10n.Reminders.emptyTitle,
                description: L10n.Reminders.emptyDescription
            )
        } else {
            RemindersList(viewModel: viewModel, dependencies: dependencies)
        }
    }
}

// MARK: - Reminders List (TableView)

private struct RemindersList: View {
    @Bindable var viewModel: RemindersListViewModel
    let dependencies: AppDependencies

    var body: some View {
        List {
            ForEach(viewModel.reminders, id: \.id) { reminder in
                NavigationLink(destination: EditReminderView(
                    viewModel: dependencies.reminderDependencyContainer.makeEditReminderViewModel(reminder: reminder)
                )) {
                    ReminderRowView(reminder: reminder) {
                        Task { await viewModel.toggleCompletion(reminder) }
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task { await viewModel.deleteReminder(id: reminder.id) }
                    } label: {
                        Label(L10n.General.delete, systemImage: "trash.fill")
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.loadReminders()
        }
    }
}

// MARK: - Add Button

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

// MARK: - Identifiable for NavigationLink
extension Reminder: Identifiable {}
