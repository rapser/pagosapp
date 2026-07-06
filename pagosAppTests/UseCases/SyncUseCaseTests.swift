//
//  SyncUseCaseTests.swift
//  pagosAppTests
//
//  Unit tests for SyncPaymentsUseCase and SyncRemindersUseCase orchestrators.
//

import Foundation
import Testing
@testable import pagosApp

// MARK: - SyncPaymentsUseCase

@Suite("SyncPaymentsUseCase")
@MainActor
struct SyncPaymentsUseCaseTests {
    let syncRepo = MockPaymentSyncRepository()
    let repo = MockPaymentRepository()

    private func makeSUT() -> SyncPaymentsUseCase {
        let uploadUseCase = UploadLocalChangesUseCase(syncRepository: syncRepo, log: NullLog())
        let downloadUseCase = DownloadRemoteChangesUseCase(
            syncRepository: syncRepo, paymentRepository: repo, log: NullLog()
        )
        return SyncPaymentsUseCase(uploadUseCase: uploadUseCase, downloadUseCase: downloadUseCase)
    }

    @Test func bothSucceed_returnsSuccess() async {
        syncRepo.pendingPayments = [Payment.make()]

        let result = await makeSUT().execute()

        if case .failure(let error) = result { Issue.record("Expected success, got \(error)") }
    }

    @Test func uploadFails_returnsFailure_doesNotDownload() async {
        syncRepo.shouldThrowOnGetUserId = true
        syncRepo.pendingPayments = [Payment.make()]

        let result = await makeSUT().execute()

        guard case .failure = result else {
            Issue.record("Expected .failure")
            return
        }
        #expect(repo.payments.isEmpty, "Download should not have run after upload failure")
    }

    @Test func uploadSucceeds_downloadFails_returnsFailure() async {
        syncRepo.pendingPayments = []
        syncRepo.shouldThrowOnDownload = true

        let result = await makeSUT().execute()

        guard case .failure = result else {
            Issue.record("Expected .failure on download error")
            return
        }
    }

    @Test func noPendingPayments_stillDownloadsFromRemote() async {
        syncRepo.pendingPayments = []
        syncRepo.remotePaymentsToReturn = [Payment.make(syncStatus: .synced)]

        let result = await makeSUT().execute()

        if case .failure(let error) = result { Issue.record("Expected success, got \(error)") }
        #expect(repo.payments.count == 1, "Remote payment should have been saved locally")
    }

    @Test func pendingPayments_uploaded_thenRemoteDownloaded() async {
        let pending = Payment.make(syncStatus: .local)
        syncRepo.pendingPayments = [pending]
        syncRepo.remotePaymentsToReturn = [Payment.make(syncStatus: .synced)]

        let result = await makeSUT().execute()

        if case .failure(let error) = result { Issue.record("Expected success, got \(error)") }
        #expect(syncRepo.uploadCount == 1, "Should have uploaded once")
        #expect(repo.payments.count == 1, "Remote payment should have been downloaded")
    }
}

// MARK: - SyncRemindersUseCase

@Suite("SyncRemindersUseCase")
@MainActor
struct SyncRemindersUseCaseTests {
    let syncRepo = MockReminderSyncRepository()
    let localDS = MockReminderLocalDataSource()

    private func makeSUT() -> SyncRemindersUseCase {
        let uploadUseCase = UploadReminderChangesUseCase(syncRepository: syncRepo, log: NullLog())
        let downloadUseCase = DownloadReminderChangesUseCase(
            syncRepository: syncRepo, localDataSource: localDS, log: NullLog()
        )
        return SyncRemindersUseCase(uploadUseCase: uploadUseCase, downloadUseCase: downloadUseCase)
    }

    @Test func bothSucceed_returnsSuccess() async {
        syncRepo.pendingReminders = [Reminder.make()]

        let result = await makeSUT().execute()

        if case .failure(let error) = result { Issue.record("Expected success, got \(error)") }
    }

    @Test func uploadFails_returnsFailure_doesNotDownload() async {
        syncRepo.shouldThrowOnGetUserId = true
        syncRepo.pendingReminders = [Reminder.make()]

        let result = await makeSUT().execute()

        guard case .failure = result else {
            Issue.record("Expected .failure")
            return
        }
        #expect(localDS.savedBatches.isEmpty, "Download should not have run after upload failure")
    }

    @Test func noPendingReminders_downloadsFromRemote() async {
        syncRepo.pendingReminders = []
        syncRepo.remoteReminders = [Reminder.make(title: "Remote Reminder", syncStatus: .synced)]

        let result = await makeSUT().execute()

        if case .failure(let error) = result { Issue.record("Expected success, got \(error)") }
        #expect(localDS.reminders.count == 1, "Remote reminder should have been saved locally")
    }

    @Test func localModifiedReminder_preserved_afterSync() async {
        let id = UUID()
        let remote = Reminder.make(id: id, title: "Remote Title", syncStatus: .synced)
        let local = Reminder.make(id: id, title: "My Local Edits", syncStatus: .modified)
        syncRepo.pendingReminders = []
        syncRepo.remoteReminders = [remote]
        localDS.reminders = [local]

        _ = await makeSUT().execute()

        let preserved = localDS.reminders.first { $0.id == id }
        #expect(preserved?.title == "My Local Edits", "Modified local reminder must not be overwritten by remote")
    }
}
