//
//  UseCaseMocks.swift
//  pagosAppTests
//
//  Shared mocks and test fixtures for use case unit tests.
//

import Foundation
import LocalAuthentication
@testable import pagosApp

// MARK: - NullLog

struct NullLog: DomainLogWriter {
    func debug(_ message: String, category: String) {}
    func info(_ message: String, category: String) {}
    func warning(_ message: String, category: String) {}
    func error(_ message: String, category: String) {}
}

// MARK: - SpyEventBus

@MainActor
final class SpyEventBus: EventBus {
    private(set) var publishedEvents: [any DomainEvent] = []
    private var continuations: [String: [any Continuation]] = [:]

    private protocol Continuation: AnyObject {
        func yield(_ event: any DomainEvent)
    }

    private final class TypedContinuation<T: DomainEvent>: Continuation, @unchecked Sendable {
        let continuation: AsyncStream<T>.Continuation

        init(continuation: AsyncStream<T>.Continuation) {
            self.continuation = continuation
        }

        func yield(_ event: any DomainEvent) {
            guard let typedEvent = event as? T else { return }
            continuation.yield(typedEvent)
        }
    }

    func publish<T: DomainEvent>(_ event: T) {
        publishedEvents.append(event)

        let typeName = String(describing: T.self)
        continuations[typeName]?.forEach { $0.yield(event) }
    }

    func subscribe<T: DomainEvent>(to eventType: T.Type) -> AsyncStream<T> {
        let typeName = String(describing: eventType)

        return AsyncStream { continuation in
            let wrapper = TypedContinuation(continuation: continuation)
            continuations[typeName, default: []].append(wrapper)

            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    self.continuations[typeName]?.removeAll { $0 === wrapper }
                    if self.continuations[typeName]?.isEmpty == true {
                        self.continuations.removeValue(forKey: typeName)
                    }
                }
            }
        }
    }

    func lastEvent<T: DomainEvent>(ofType type: T.Type) -> T? {
        publishedEvents.compactMap { $0 as? T }.last
    }

    var totalEventCount: Int { publishedEvents.count }
}

// MARK: - MockPaymentRepository

final class MockPaymentRepository: PaymentRepositoryProtocol, @unchecked Sendable {
    var payments: [Payment] = []
    var shouldThrowOnSave = false
    var shouldThrowOnDelete = false
    var shouldThrowOnRemoteDelete = false
    private(set) var savedPayments: [Payment] = []
    private(set) var deletedIds: [UUID] = []
    private(set) var remoteDeletedIds: [UUID] = []

    nonisolated func fetchAllPayments(userId: UUID) async throws -> [PaymentDTO] { [] }
    nonisolated func upsertPayment(userId: UUID, payment: PaymentDTO) async throws {}
    nonisolated func upsertPayments(userId: UUID, payments: [PaymentDTO]) async throws {}
    nonisolated func deletePayment(paymentId: UUID) async throws {
        if shouldThrowOnRemoteDelete { throw PaymentError.deleteFailed("remote mock") }
        remoteDeletedIds.append(paymentId)
    }
    nonisolated func deletePayments(paymentIds: [UUID]) async throws {
        for id in paymentIds { try await deletePayment(paymentId: id) }
    }

    @MainActor func getAllLocalPayments() async throws -> [Payment] { payments }
    @MainActor func getLocalPayment(id: UUID) async throws -> Payment? { payments.first { $0.id == id } }

    @MainActor func savePayment(_ payment: Payment) async throws {
        if shouldThrowOnSave { throw PaymentError.saveFailed("mock") }
        payments.removeAll { $0.id == payment.id }
        payments.append(payment)
        savedPayments.append(payment)
    }

    @MainActor func savePayments(_ ps: [Payment]) async throws {
        for p in ps { try await savePayment(p) }
    }

    @MainActor func deleteLocalPayment(id: UUID) async throws {
        if shouldThrowOnDelete { throw PaymentError.deleteFailed("mock") }
        payments.removeAll { $0.id == id }
        deletedIds.append(id)
    }

    @MainActor func deleteLocalPayments(ids: [UUID]) async throws {
        for id in ids { try await deleteLocalPayment(id: id) }
    }

    @MainActor func clearAllLocalPayments() async throws { payments = [] }
}

// MARK: - MockPaymentSyncRepository

final class MockPaymentSyncRepository: PaymentSyncRepositoryProtocol, @unchecked Sendable {
    var userIdToReturn: UUID = UUID()
    var shouldThrowOnGetUserId = false
    var shouldThrowOnGetCount = false
    var pendingPayments: [Payment] = []
    private(set) var uploadCount: Int = 0

    func getCurrentUserId() async throws -> UUID {
        if shouldThrowOnGetUserId { throw PaymentSyncError.notAuthenticated }
        return userIdToReturn
    }

    @MainActor func uploadPayments(_ payments: [Payment], userId: UUID) async throws {
        uploadCount += 1
    }

    var remotePaymentsToReturn: [Payment] = []
    var shouldThrowOnDownload = false

    func downloadPayments(userId: UUID) async throws -> [Payment] {
        if shouldThrowOnDownload { throw PaymentSyncError.downloadFailed("mock") }
        return remotePaymentsToReturn
    }
    func syncDeletion(paymentId: UUID) async throws {}

    @MainActor func getPendingPayments() async throws -> [Payment] { pendingPayments }

    @MainActor func getPendingSyncCount() async throws -> Int {
        if shouldThrowOnGetCount { throw PaymentSyncError.networkError }
        return pendingPayments.count
    }

    @MainActor func updateSyncStatus(paymentId: UUID, status: SyncStatus) async throws {}
}

// MARK: - MockReminderRepository

final class MockReminderRepository: ReminderRepositoryProtocol, @unchecked Sendable {
    var reminders: [Reminder] = []
    private(set) var savedReminder: Reminder?

    @MainActor func create(reminder: Reminder) async -> Result<Reminder, ReminderError> {
        savedReminder = reminder
        reminders.append(reminder)
        return .success(reminder)
    }

    @MainActor func getAll() async -> Result<[Reminder], ReminderError> { .success(reminders) }

    @MainActor func getById(id: UUID) async -> Result<Reminder?, ReminderError> {
        .success(reminders.first { $0.id == id })
    }

    @MainActor func update(reminder: Reminder) async -> Result<Reminder, ReminderError> {
        savedReminder = reminder
        reminders.removeAll { $0.id == reminder.id }
        reminders.append(reminder)
        return .success(reminder)
    }

    @MainActor func delete(id: UUID) async -> Result<Void, ReminderError> {
        reminders.removeAll { $0.id == id }
        return .success(())
    }
}

// MARK: - MockReminderSyncRepository

final class MockReminderSyncRepository: ReminderSyncRepositoryProtocol, @unchecked Sendable {
    var userIdToReturn: UUID = UUID()
    var shouldThrowOnGetUserId = false
    var pendingReminders: [Reminder] = []
    var remoteReminders: [Reminder] = []
    private(set) var uploadCount: Int = 0

    func getCurrentUserId() async throws -> UUID {
        if shouldThrowOnGetUserId { throw ReminderSyncError.notAuthenticated }
        return userIdToReturn
    }

    @MainActor func uploadReminders(_ reminders: [Reminder], userId: UUID) async throws {
        uploadCount += 1
    }

    func downloadReminders(userId: UUID) async throws -> [Reminder] { remoteReminders }
    func syncDeletion(reminderId: UUID) async throws {}

    @MainActor func getPendingReminders() async throws -> [Reminder] { pendingReminders }
    @MainActor func getPendingSyncCount() async throws -> Int { pendingReminders.count }
    @MainActor func updateSyncStatus(reminderId: UUID, status: ReminderSyncStatus) async throws {}
}

// MARK: - MockReminderLocalDataSource

@MainActor
final class MockReminderLocalDataSource: ReminderLocalDataSource {
    var reminders: [Reminder] = []
    private(set) var savedBatches: [[Reminder]] = []
    private(set) var deletedIds: [UUID] = []

    func fetchAll() async throws -> [Reminder] { reminders }
    func fetchPaginated(page: Int, pageSize: Int) async throws -> [Reminder] { reminders }
    func fetchCount() async throws -> Int { reminders.count }
    func fetch(id: UUID) async throws -> Reminder? { reminders.first { $0.id == id } }

    func save(_ reminder: Reminder) async throws {
        reminders.removeAll { $0.id == reminder.id }
        reminders.append(reminder)
    }

    func saveAll(_ batch: [Reminder]) async throws {
        savedBatches.append(batch)
        for reminder in batch {
            reminders.removeAll { $0.id == reminder.id }
            reminders.append(reminder)
        }
    }

    func delete(id: UUID) async throws {
        reminders.removeAll { $0.id == id }
        deletedIds.append(id)
    }
}

// MARK: - MockStatisticsRepository

@MainActor
final class MockStatisticsRepository: StatisticsRepositoryProtocol {
    var allPayments: [Payment] = []
    var filteredPayments: [Payment] = []
    var monthlyPayments: [Payment] = []
    var shouldFail = false
    var shouldFailAllPayments = false
    var shouldFailFilteredPayments = false
    var shouldFailMonthlyPayments = false

    func getAllPayments() async -> Result<[Payment], PaymentError> {
        shouldFail || shouldFailAllPayments ? .failure(.notFound) : .success(allPayments)
    }

    func getFilteredPayments(filter: StatsFilter, currency: Currency) async -> Result<[Payment], PaymentError> {
        shouldFail || shouldFailFilteredPayments ? .failure(.notFound) : .success(filteredPayments)
    }

    func getPaymentsForLastMonths(count: Int, currency: Currency) async -> Result<[Payment], PaymentError> {
        shouldFail || shouldFailMonthlyPayments ? .failure(.notFound) : .success(monthlyPayments)
    }
}

// MARK: - MockSettingsSyncRepository

@MainActor
final class MockSettingsSyncRepository: SettingsSyncRepositoryProtocol {
    var performSyncCallCount = 0
    var clearLocalDatabaseCallCount = 0
    var updatePendingSyncCountCallCount = 0
    var pendingSyncCount = 0
    var syncError: Error?
    var shouldThrowOnPerformSync = false
    var clearLocalDatabaseResult = true

    func performSync() async throws {
        performSyncCallCount += 1
        if shouldThrowOnPerformSync {
            throw PaymentSyncError.networkError
        }
    }

    func clearLocalDatabase(force: Bool) async -> Bool {
        _ = force
        clearLocalDatabaseCallCount += 1
        return clearLocalDatabaseResult
    }

    func updatePendingSyncCount() async {
        updatePendingSyncCountCallCount += 1
    }
}

// MARK: - MockAuthSessionRepository

@MainActor
final class MockAuthSessionRepository: AuthSessionRepositoryProtocol {
    var signOutResult: Result<Void, AuthError> = .success(())

    func signUp(credentials: RegistrationCredentials) async -> Result<AuthSession, AuthError> {
        _ = credentials
        return .failure(.unknown("unused"))
    }

    func signIn(credentials: LoginCredentials) async -> Result<AuthSession, AuthError> {
        _ = credentials
        return .failure(.unknown("unused"))
    }

    func signOut() async -> Result<Void, AuthError> {
        signOutResult
    }

    func getCurrentSession() async -> AuthSession? { nil }

    func refreshSession(refreshToken: String) async -> Result<AuthSession, AuthError> {
        _ = refreshToken
        return .failure(.unknown("unused"))
    }

    func getCurrentUserId() async -> UUID? { nil }
}

// MARK: - MockSessionRepository

@MainActor
final class MockSessionRepository: SessionRepositoryProtocol {
    var hasActiveSession = false
    var lastActiveTimestamp: Date?
    var isSessionExpiredSync = false

    func startSession() async {}
    func endSession() async {}
    func clearSession() async {}
    func updateLastActiveTimestamp() async {}
    func isSessionExpired() async -> Bool { false }
    func sessionTimeRemaining() async -> TimeInterval { 0 }
    func validateSession() async -> Result<Bool, AuthError> { .success(true) }
}

// MARK: - MockUserProfileRepository

final class MockUserProfileRepository: UserProfileRepositoryProtocol, @unchecked Sendable {
    nonisolated func fetchProfile(userId: UUID) async -> Result<UserProfile, UserProfileError> {
        _ = userId
        return .failure(.profileNotFound)
    }

    nonisolated func updateProfile(_ profile: UserProfile) async -> Result<UserProfile, UserProfileError> {
        .success(profile)
    }

    @MainActor
    func getLocalProfile() async -> Result<UserProfile?, UserProfileError> {
        .success(nil)
    }

    @MainActor
    func saveLocalProfile(_ profile: UserProfile) async -> Result<Void, UserProfileError> {
        _ = profile
        return .success(())
    }

    @MainActor
    func deleteLocalProfile() async -> Result<Void, UserProfileError> {
        .success(())
    }
}

// MARK: - MockBiometricCredentialsDataSource

final class MockBiometricCredentialsDataSource: BiometricCredentialsDataSource {
    func saveCredentials(email: String, password: String) -> Bool {
        _ = email
        _ = password
        return true
    }

    func retrieveCredentials(context: LAContext?) -> (email: String, password: String)? {
        _ = context
        return nil
    }

    func deleteCredentials() -> Bool { true }
    func hasStoredCredentials() -> Bool { false }
    func setHasLoggedIn(_ value: Bool) -> Bool {
        _ = value
        return true
    }
    func getHasLoggedIn() -> Bool { false }
    func deleteHasLoggedIn() -> Bool { true }
}

// MARK: - Test Fixtures

extension Payment {
    static func make(
        id: UUID = UUID(),
        name: String = "Test Payment",
        amount: Decimal = 100,
        currency: Currency = .pen,
        dueDate: Date = Date(),
        isPaid: Bool = false,
        category: PaymentCategory = .servicios,
        eventIdentifier: String? = nil,
        syncStatus: SyncStatus = .local,
        lastSyncedAt: Date? = nil,
        groupId: UUID? = nil
    ) -> Payment {
        Payment(
            id: id, name: name, amount: amount, currency: currency,
            dueDate: dueDate, isPaid: isPaid, category: category,
            eventIdentifier: eventIdentifier, syncStatus: syncStatus,
            lastSyncedAt: lastSyncedAt, groupId: groupId
        )
    }
}

extension PaymentUI {
    static func make(
        id: UUID = UUID(),
        name: String = "Test Payment",
        amount: Double = 100.0,
        currency: Currency = .pen,
        dueDate: Date = Date(),
        isPaid: Bool = false,
        category: PaymentCategory = .servicios,
        eventIdentifier: String? = nil,
        syncStatus: SyncStatus = .local,
        lastSyncedAt: Date? = nil,
        groupId: UUID? = nil
    ) -> PaymentUI {
        PaymentUI(
            id: id, name: name, amount: amount, currency: currency,
            dueDate: dueDate, isPaid: isPaid, category: category,
            eventIdentifier: eventIdentifier, syncStatus: syncStatus,
            lastSyncedAt: lastSyncedAt, groupId: groupId
        )
    }
}

extension Reminder {
    static func make(
        id: UUID = UUID(),
        type: ReminderType = .other,
        title: String = "Test Reminder",
        description: String = "",
        dueDate: Date = Date(),
        isCompleted: Bool = false,
        syncStatus: ReminderSyncStatus = .local,
        lastSyncedAt: Date? = nil
    ) -> Reminder {
        Reminder(
            id: id, reminderType: type, title: title, description: description,
            dueDate: dueDate, isCompleted: isCompleted,
            notificationSettings: NotificationSettings(),
            syncStatus: syncStatus, lastSyncedAt: lastSyncedAt
        )
    }
}
