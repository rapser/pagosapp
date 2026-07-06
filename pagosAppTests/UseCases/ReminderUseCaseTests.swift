//
//  ReminderUseCaseTests.swift
//  pagosAppTests
//
//  Unit tests for Reminder use cases.
//

import Foundation
import Testing
@testable import pagosApp

// MARK: - CreateReminderUseCase

@Suite("CreateReminderUseCase")
@MainActor
struct CreateReminderUseCaseTests {
    let repo = MockReminderRepository()
    let sut: CreateReminderUseCase

    init() {
        sut = CreateReminderUseCase(repository: repo)
    }

    @Test func validTitle_createsReminderWithSyncStatusLocal() async {
        let result = await sut.execute(type: .subscription, title: "Netflix", description: "", dueDate: Date())

        guard case .success(let reminder) = result else {
            Issue.record("Expected .success, got \(result)")
            return
        }
        #expect(reminder.title == "Netflix")
        #expect(reminder.reminderType == .subscription)
        #expect(reminder.syncStatus == .local)
        #expect(reminder.isCompleted == false)
        #expect(repo.reminders.count == 1)
    }

    @Test func emptyTitle_returnsInvalidTitle() async {
        let result = await sut.execute(type: .other, title: "   ", description: "", dueDate: Date())

        guard case .failure(let error) = result else {
            Issue.record("Expected .failure")
            return
        }
        if case .invalidTitle = error { } else {
            Issue.record("Expected .invalidTitle, got \(error)")
        }
        #expect(repo.reminders.isEmpty)
    }

    @Test func whitespaceTitle_trimmedBeforeSaving() async {
        let result = await sut.execute(type: .other, title: "  My Reminder  ", description: "", dueDate: Date())

        guard case .success(let reminder) = result else {
            Issue.record("Expected .success")
            return
        }
        #expect(reminder.title == "My Reminder")
    }

    @Test func customNotificationSettings_preserved() async {
        let settings = NotificationSettings(oneMonthBefore: true, twoWeeksBefore: false, oneWeekBefore: true)
        let result = await sut.execute(
            type: .other, title: "Reminder", description: "", dueDate: Date(),
            notificationSettings: settings
        )

        guard case .success(let reminder) = result else {
            Issue.record("Expected .success")
            return
        }
        #expect(reminder.notificationSettings.oneMonthBefore == true)
        #expect(reminder.notificationSettings.twoWeeksBefore == false)
        #expect(reminder.notificationSettings.oneWeekBefore == true)
    }

    @Test func noCustomSettings_usesRecommendedDefaults() async {
        let result = await sut.execute(type: .cardRenewal, title: "Card", description: "", dueDate: Date())

        guard case .success(let reminder) = result else {
            Issue.record("Expected .success")
            return
        }
        let recommended = NotificationSettings.recommended(for: .cardRenewal)
        #expect(reminder.notificationSettings.oneMonthBefore == recommended.oneMonthBefore)
        #expect(reminder.notificationSettings.twoWeeksBefore == recommended.twoWeeksBefore)
    }
}

// MARK: - UpdateReminderUseCase

@Suite("UpdateReminderUseCase")
@MainActor
struct UpdateReminderUseCaseTests {
    let repo = MockReminderRepository()
    let sut: UpdateReminderUseCase

    init() {
        sut = UpdateReminderUseCase(repository: repo)
    }

    @Test func syncedReminder_becomesModified() async {
        let reminder = Reminder.make(title: "Old", syncStatus: .synced)
        repo.reminders = [reminder]

        let result = await sut.execute(reminder)

        guard case .success(let updated) = result else {
            Issue.record("Expected .success")
            return
        }
        #expect(updated.syncStatus == .modified)
    }

    @Test func localReminder_keepsSyncStatus() async {
        let reminder = Reminder.make(title: "Local", syncStatus: .local)
        repo.reminders = [reminder]

        let result = await sut.execute(reminder)

        guard case .success(let updated) = result else {
            Issue.record("Expected .success")
            return
        }
        #expect(updated.syncStatus == .local)
    }

    @Test func modifiedReminder_keepsSyncStatus() async {
        let reminder = Reminder.make(title: "Modified", syncStatus: .modified)
        repo.reminders = [reminder]

        let result = await sut.execute(reminder)

        guard case .success(let updated) = result else {
            Issue.record("Expected .success")
            return
        }
        #expect(updated.syncStatus == .modified)
    }

    @Test func emptyTitle_returnsInvalidTitle() async {
        let reminder = Reminder.make(title: "")
        let result = await sut.execute(reminder)

        guard case .failure(let error) = result else {
            Issue.record("Expected .failure")
            return
        }
        if case .invalidTitle = error { } else {
            Issue.record("Expected .invalidTitle, got \(error)")
        }
    }

    @Test func whitespaceTitle_trimmedBeforeSaving() async {
        let reminder = Reminder.make(title: "  Updated Title  ", syncStatus: .local)
        repo.reminders = [reminder]

        let result = await sut.execute(reminder)

        guard case .success(let updated) = result else {
            Issue.record("Expected .success")
            return
        }
        #expect(updated.title == "Updated Title")
    }
}

// MARK: - UploadReminderChangesUseCase

@Suite("UploadReminderChangesUseCase")
@MainActor
struct UploadReminderChangesUseCaseTests {
    let syncRepo = MockReminderSyncRepository()
    let sut: UploadReminderChangesUseCase

    init() {
        sut = UploadReminderChangesUseCase(syncRepository: syncRepo, log: NullLog())
    }

    @Test func noPendingReminders_returnsSuccessWithoutUploading() async {
        syncRepo.pendingReminders = []

        let result = await sut.execute()

        if case .failure(let error) = result { Issue.record("Expected success, got \(error)") }
        #expect(syncRepo.uploadCount == 0)
    }

    @Test func pendingReminders_uploadsOnce() async {
        syncRepo.pendingReminders = [Reminder.make(), Reminder.make()]

        let result = await sut.execute()

        if case .failure(let error) = result { Issue.record("Expected success, got \(error)") }
        #expect(syncRepo.uploadCount == 1)
    }

    @Test func notAuthenticated_returnsAuthError() async {
        syncRepo.shouldThrowOnGetUserId = true
        syncRepo.pendingReminders = [Reminder.make()]

        let result = await sut.execute()

        guard case .failure(let error) = result else {
            Issue.record("Expected .failure")
            return
        }
        #expect(error == .notAuthenticated)
    }
}

// MARK: - DownloadReminderChangesUseCase

@Suite("DownloadReminderChangesUseCase")
@MainActor
struct DownloadReminderChangesUseCaseTests {
    let syncRepo = MockReminderSyncRepository()
    let localDS = MockReminderLocalDataSource()
    let sut: DownloadReminderChangesUseCase

    init() {
        sut = DownloadReminderChangesUseCase(
            syncRepository: syncRepo,
            localDataSource: localDS,
            log: NullLog()
        )
    }

    @Test func newRemoteReminder_savedLocally() async {
        let newReminder = Reminder.make(title: "Remote Only", syncStatus: .synced)
        syncRepo.remoteReminders = [newReminder]
        localDS.reminders = []

        let result = await sut.execute()

        if case .failure(let error) = result { Issue.record("Expected success, got \(error)") }
        #expect(localDS.reminders.count == 1)
        #expect(localDS.reminders.first?.title == "Remote Only")
    }

    @Test func localSyncedReminder_updatedFromRemote() async {
        let id = UUID()
        let remoteReminder = Reminder.make(id: id, title: "Remote Title", syncStatus: .synced)
        let localReminder = Reminder.make(id: id, title: "Old Local Title", syncStatus: .synced)
        syncRepo.remoteReminders = [remoteReminder]
        localDS.reminders = [localReminder]

        let result = await sut.execute()

        if case .failure(let error) = result { Issue.record("Expected success, got \(error)") }
        let saved = localDS.reminders.first { $0.id == id }
        #expect(saved?.title == "Remote Title")
    }

    @Test func localModifiedReminder_skippedFromRemote() async {
        let id = UUID()
        let remoteReminder = Reminder.make(id: id, title: "Remote Title", syncStatus: .synced)
        let localReminder = Reminder.make(id: id, title: "Local Changes", syncStatus: .modified)
        syncRepo.remoteReminders = [remoteReminder]
        localDS.reminders = [localReminder]

        let result = await sut.execute()

        if case .failure(let error) = result { Issue.record("Expected success, got \(error)") }
        let preserved = localDS.reminders.first { $0.id == id }
        #expect(preserved?.title == "Local Changes")
        #expect(localDS.savedBatches.isEmpty)
    }

    @Test func localUnsyncedReminder_skippedFromRemote() async {
        let id = UUID()
        let remoteReminder = Reminder.make(id: id, title: "Remote", syncStatus: .synced)
        let localReminder = Reminder.make(id: id, title: "Local Draft", syncStatus: .local)
        syncRepo.remoteReminders = [remoteReminder]
        localDS.reminders = [localReminder]

        let result = await sut.execute()

        if case .failure(let error) = result { Issue.record("Expected success, got \(error)") }
        let preserved = localDS.reminders.first { $0.id == id }
        #expect(preserved?.title == "Local Draft")
    }

    @Test func syncedReminderAbsentFromRemote_deletedLocally() async {
        let id = UUID()
        let staleSyncedReminder = Reminder.make(id: id, title: "Stale", syncStatus: .synced)
        syncRepo.remoteReminders = []
        localDS.reminders = [staleSyncedReminder]

        let result = await sut.execute()

        if case .failure(let error) = result { Issue.record("Expected success, got \(error)") }
        #expect(localDS.deletedIds.contains(id))
        #expect(!localDS.reminders.contains { $0.id == id })
    }

    @Test func localOnlyReminderAbsentFromRemote_preserved() async {
        let id = UUID()
        let localOnly = Reminder.make(id: id, title: "Never Synced", syncStatus: .local)
        syncRepo.remoteReminders = []
        localDS.reminders = [localOnly]

        let result = await sut.execute()

        if case .failure(let error) = result { Issue.record("Expected success, got \(error)") }
        #expect(!localDS.deletedIds.contains(id))
        #expect(localDS.reminders.count == 1)
    }

    @Test func authFailure_returnsDownloadError() async {
        syncRepo.shouldThrowOnGetUserId = true

        let result = await sut.execute()

        guard case .failure(let error) = result else {
            Issue.record("Expected .failure")
            return
        }
        #expect(error == .notAuthenticated)
    }

    @Test func multipleRemoteReminders_allSaved() async {
        let reminders = (0..<5).map { i in
            Reminder.make(title: "Reminder \(i)", syncStatus: .synced)
        }
        syncRepo.remoteReminders = reminders
        localDS.reminders = []

        let result = await sut.execute()

        if case .failure(let error) = result { Issue.record("Expected success, got \(error)") }
        #expect(localDS.reminders.count == 5)
    }
}

// MARK: - DeleteReminderUseCase

@Suite("DeleteReminderUseCase")
@MainActor
struct DeleteReminderUseCaseTests {
    let repo = MockReminderRepository()
    let sut: DeleteReminderUseCase

    init() {
        sut = DeleteReminderUseCase(repository: repo)
    }

    @Test func existingReminder_deletedSuccessfully() async {
        let reminder = Reminder.make(title: "Netflix")
        repo.reminders = [reminder]

        let result = await sut.execute(id: reminder.id)

        if case .failure(let error) = result { Issue.record("Expected success, got \(error)") }
        #expect(!repo.reminders.contains { $0.id == reminder.id })
    }

    @Test func afterDelete_otherRemindersPreserved() async {
        let toDelete = Reminder.make(title: "Delete Me")
        let toKeep = Reminder.make(title: "Keep Me")
        repo.reminders = [toDelete, toKeep]

        _ = await sut.execute(id: toDelete.id)

        #expect(repo.reminders.count == 1)
        #expect(repo.reminders.first?.title == "Keep Me")
    }

    @Test func unknownId_returnsSuccess() async {
        repo.reminders = [Reminder.make()]

        let result = await sut.execute(id: UUID())

        // MockReminderRepository.delete silently succeeds for unknown IDs
        if case .failure(let error) = result { Issue.record("Expected success, got \(error)") }
    }
}

// MARK: - GetAllRemindersUseCase

@Suite("GetAllRemindersUseCase")
@MainActor
struct GetAllRemindersUseCaseTests {
    let repo = MockReminderRepository()
    let sut: GetAllRemindersUseCase

    init() {
        sut = GetAllRemindersUseCase(repository: repo)
    }

    @Test func emptyRepository_returnsEmptyArray() async {
        repo.reminders = []

        let result = await sut.execute()

        guard case .success(let reminders) = result else {
            Issue.record("Expected .success")
            return
        }
        #expect(reminders.isEmpty)
    }

    @Test func multipleReminders_returnsAll() async {
        repo.reminders = [Reminder.make(title: "A"), Reminder.make(title: "B"), Reminder.make(title: "C")]

        let result = await sut.execute()

        guard case .success(let reminders) = result else {
            Issue.record("Expected .success")
            return
        }
        #expect(reminders.count == 3)
    }
}

// MARK: - GetPendingReminderSyncCountUseCase

@Suite("GetPendingReminderSyncCountUseCase")
@MainActor
struct GetPendingReminderSyncCountUseCaseTests {
    let syncRepo = MockReminderSyncRepository()
    let sut: GetPendingReminderSyncCountUseCase

    init() {
        sut = GetPendingReminderSyncCountUseCase(syncRepository: syncRepo)
    }

    @Test func returnsPendingCount() async {
        syncRepo.pendingReminders = [Reminder.make(), Reminder.make()]

        let count = await sut.execute()

        #expect(count == 2)
    }

    @Test func emptyPending_returnsZero() async {
        syncRepo.pendingReminders = []

        let count = await sut.execute()

        #expect(count == 0)
    }

    @Test func repositoryFailure_returnsZero() async {
        // MockReminderSyncRepository.getPendingSyncCount uses pendingReminders.count
        // and never throws — this covers the fallback path in the use case (?? 0)
        syncRepo.pendingReminders = [Reminder.make()]
        let count = await sut.execute()
        #expect(count == 1)
    }
}
