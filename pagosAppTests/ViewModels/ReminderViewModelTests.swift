//
//  ReminderViewModelTests.swift
//  pagosAppTests
//
//  Unit tests for Reminder ViewModels (RemindersListViewModel).
//

import Foundation
import Testing
@testable import pagosApp

// MARK: - RemindersListViewModel

@Suite("RemindersListViewModel")
@MainActor
struct RemindersListViewModelTests {
    let repo = MockReminderRepository()
    let sut: RemindersListViewModel

    init() {
        let getAllUseCase = GetAllRemindersUseCase(repository: repo)
        let deleteUseCase = DeleteReminderUseCase(repository: repo)
        let updateUseCase = UpdateReminderUseCase(repository: repo)
        sut = RemindersListViewModel(
            getAllRemindersUseCase: getAllUseCase,
            deleteReminderUseCase: deleteUseCase,
            updateReminderUseCase: updateUseCase
        )
    }

    @Test func loadReminders_populatesList() async {
        repo.reminders = [Reminder.make(title: "Netflix"), Reminder.make(title: "Spotify")]

        await sut.loadReminders()

        #expect(sut.reminders.count == 2)
    }

    @Test func loadReminders_emptyRepo_resultInEmptyList() async {
        repo.reminders = []

        await sut.loadReminders()

        #expect(sut.reminders.isEmpty)
    }

    @Test func deleteReminder_removesFromList() async {
        let reminder = Reminder.make(title: "Netflix")
        repo.reminders = [reminder]
        await sut.loadReminders()

        await sut.deleteReminder(id: reminder.id)

        #expect(!sut.reminders.contains { $0.id == reminder.id })
    }

    @Test func toggleCompletion_flipsIsCompleted() async {
        let reminder = Reminder.make(title: "Netflix", isCompleted: false)
        repo.reminders = [reminder]
        await sut.loadReminders()

        await sut.toggleCompletion(reminder)

        #expect(sut.reminders.first { $0.id == reminder.id }?.isCompleted == true)
    }

    @Test func toggleCompletion_completedReminder_becomesIncomplete() async {
        let reminder = Reminder.make(title: "Netflix", isCompleted: true)
        repo.reminders = [reminder]
        await sut.loadReminders()

        await sut.toggleCompletion(reminder)

        #expect(sut.reminders.first { $0.id == reminder.id }?.isCompleted == false)
    }
}
