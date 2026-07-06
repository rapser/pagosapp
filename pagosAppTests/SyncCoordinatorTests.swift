//
//  SyncCoordinatorTests.swift
//  pagosAppTests
//
//  Unit tests for shared and concrete sync coordinators.
//

import Foundation
import Testing
@testable import pagosApp

private enum TestSyncFailure: Error, Equatable, Hashable {
    case recoverable
    case terminal
}

@MainActor
private final class TestSyncCoordinator: BaseSyncCoordinator<TestSyncFailure> {
    var attempts: [Result<Void, TestSyncFailure>] = []
    var clearResult = true
    var fetchedPendingCount = 0
    var completionCount = 0
    var clearCount = 0
    var retryDecisions: Set<TestSyncFailure> = []
    var terminalFailure: Error = TestSyncFailure.terminal
    var sleepCallCount = 0
    var executeCallCount = 0

    init(key: String) {
        super.init(lastSyncKey: key)
    }

    override func executeSyncAttempt() async -> Result<Void, TestSyncFailure> {
        executeCallCount += 1
        guard !attempts.isEmpty else { return .success(()) }
        return attempts.removeFirst()
    }

    override func shouldRetry(after error: TestSyncFailure) -> Bool {
        retryDecisions.contains(error)
    }

    override func terminalError(for error: TestSyncFailure) -> Error {
        _ = error
        return terminalFailure
    }

    override func fetchPendingSyncCount() async -> Int {
        fetchedPendingCount
    }

    override func performLocalDatabaseClear() async -> Bool {
        clearResult
    }

    override func didCompleteSyncSuccessfully() async {
        completionCount += 1
    }

    override func didClearLocalDatabase() async {
        clearCount += 1
    }

    override func sleepBeforeRetry(forAttempt attempt: Int) async {
        _ = attempt
        sleepCallCount += 1
    }
}

@Suite("BaseSyncCoordinator")
@MainActor
struct BaseSyncCoordinatorTests {
    @Test func alreadySyncing_skipsNewAttempt() async throws {
        let sut = TestSyncCoordinator(key: "test.sync.skip.\(UUID().uuidString)")
        sut.isSyncing = true

        try await sut.performSync()

        #expect(sut.executeCallCount == 0)
    }

    @Test func recoverableFailure_retriesAndSucceeds() async throws {
        let sut = TestSyncCoordinator(key: "test.sync.retry.\(UUID().uuidString)")
        sut.retryDecisions = [.recoverable]
        sut.fetchedPendingCount = 2
        sut.attempts = [.failure(.recoverable), .success(())]

        try await sut.performSync()

        #expect(sut.executeCallCount == 2)
        #expect(sut.sleepCallCount == 1)
        #expect(sut.pendingSyncCount == 2)
        #expect(sut.lastSyncDate != nil)
        #expect(sut.completionCount == 1)
    }

    @Test func terminalFailure_stopsWithoutRetry() async {
        let sut = TestSyncCoordinator(key: "test.sync.terminal.\(UUID().uuidString)")
        sut.retryDecisions = [.recoverable]
        sut.attempts = [.failure(.terminal)]

        await #expect(throws: TestSyncFailure.terminal) {
            try await sut.performSync()
        }

        #expect(sut.executeCallCount == 1)
        #expect(sut.sleepCallCount == 0)
    }

    @Test func clearLocalDatabase_resetsStateAfterSuccess() async {
        let sut = TestSyncCoordinator(key: "test.sync.clear.\(UUID().uuidString)")
        sut.pendingSyncCount = 4
        sut.syncError = TestSyncFailure.terminal
        sut.fetchedPendingCount = 0

        let success = await sut.clearLocalDatabase()

        #expect(success == true)
        #expect(sut.pendingSyncCount == 0)
        #expect(sut.syncError == nil)
        #expect(sut.lastSyncDate == nil)
        #expect(sut.clearCount == 1)
    }
}

@Suite("Concrete Sync Coordinators")
@MainActor
struct ConcreteSyncCoordinatorTests {
    @Test func paymentSyncSuccess_publishesPaymentsSyncedEvent() async throws {
        let syncRepository = MockPaymentSyncRepository()
        let paymentRepository = MockPaymentRepository()
        let syncUseCase = SyncPaymentsUseCase(
            uploadUseCase: UploadLocalChangesUseCase(syncRepository: syncRepository, log: NullLog()),
            downloadUseCase: DownloadRemoteChangesUseCase(
                syncRepository: syncRepository,
                paymentRepository: paymentRepository,
                log: NullLog()
            )
        )
        let bus = SpyEventBus()
        let sut = PaymentSyncCoordinator(
            syncPaymentsUseCase: syncUseCase,
            getPendingSyncCountUseCase: GetPendingSyncCountUseCase(syncRepository: syncRepository),
            uploadLocalChangesUseCase: UploadLocalChangesUseCase(syncRepository: syncRepository, log: NullLog()),
            downloadRemoteChangesUseCase: DownloadRemoteChangesUseCase(
                syncRepository: syncRepository,
                paymentRepository: paymentRepository,
                log: NullLog()
            ),
            paymentRepository: paymentRepository,
            syncRepository: syncRepository,
            eventBus: bus
        )

        try await sut.performSync()

        #expect(bus.lastEvent(ofType: PaymentsSyncedEvent.self) != nil)
    }

    @Test func reminderSyncSuccess_reschedulesNotifications() async throws {
        let syncRepository = MockReminderSyncRepository()
        let localDataSource = MockReminderLocalDataSource()
        let notificationDataSource = MockNotificationDataSource()
        localDataSource.reminders = [
            Reminder.make(title: "Netflix", isCompleted: false),
            Reminder.make(title: "Done", isCompleted: true),
        ]

        let sut = ReminderSyncCoordinator(
            syncRemindersUseCase: SyncRemindersUseCase(
                uploadUseCase: UploadReminderChangesUseCase(syncRepository: syncRepository, log: NullLog()),
                downloadUseCase: DownloadReminderChangesUseCase(
                    syncRepository: syncRepository,
                    localDataSource: localDataSource,
                    log: NullLog()
                )
            ),
            getPendingSyncCountUseCase: GetPendingReminderSyncCountUseCase(syncRepository: syncRepository),
            syncRepository: syncRepository,
            localDataSource: localDataSource,
            rescheduleNotificationsUseCase: RescheduleReminderNotificationsUseCase(
                notificationDataSource: notificationDataSource,
                log: NullLog()
            ),
            log: NullLog()
        )

        try await sut.performSync()

        #expect(notificationDataSource.scheduledReminderIds.count == 1)
        #expect(notificationDataSource.cancelledReminderIds.count == 1)
    }
}
