//
//  PaymentUseCaseTests.swift
//  pagosAppTests
//
//  Unit tests for Payment use cases.
//

import Foundation
import Testing
@testable import pagosApp

// MARK: - PaymentValidator

@Suite("PaymentValidator")
@MainActor
struct PaymentValidatorTests {
    let validator = PaymentValidator()

    @Test func validPayment_passes() throws {
        let payment = Payment.make(name: "Netflix", amount: 50)
        try validator.validate(payment)
    }

    @Test func emptyName_throwsInvalidName() {
        let payment = Payment.make(name: "   ")
        #expect(throws: PaymentError.invalidName) {
            try validator.validate(payment)
        }
    }

    @Test func zeroAmount_throwsInvalidAmount() {
        let payment = Payment.make(amount: 0)
        #expect(throws: PaymentError.invalidAmount) {
            try validator.validate(payment)
        }
    }

    @Test func negativeAmount_throwsInvalidAmount() {
        let payment = Payment.make(amount: -10)
        #expect(throws: PaymentError.invalidAmount) {
            try validator.validate(payment)
        }
    }
}

// MARK: - CreatePaymentUseCase

@Suite("CreatePaymentUseCase")
@MainActor
struct CreatePaymentUseCaseTests {
    let repo = MockPaymentRepository()
    let bus = SpyEventBus()
    let sut: CreatePaymentUseCase

    init() {
        sut = CreatePaymentUseCase(paymentRepository: repo, eventBus: bus, log: NullLog())
    }

    @Test func validPayment_savesAndPublishesCreatedEvent() async {
        let payment = Payment.make(name: "Netflix", amount: 50)
        let result = await sut.execute(payment)

        guard case .success(let saved) = result else {
            Issue.record("Expected .success, got \(result)")
            return
        }
        #expect(saved.id == payment.id)
        #expect(repo.payments.contains { $0.id == payment.id })
        #expect(bus.lastEvent(ofType: PaymentCreatedEvent.self)?.paymentId == payment.id)
    }

    @Test func emptyName_returnsValidationError() async {
        let payment = Payment.make(name: "  ")
        let result = await sut.execute(payment)

        guard case .failure(let error) = result else {
            Issue.record("Expected .failure")
            return
        }
        #expect(error == .invalidName)
        #expect(repo.payments.isEmpty)
        #expect(bus.totalEventCount == 0)
    }

    @Test func zeroAmount_returnsValidationError() async {
        let payment = Payment.make(amount: 0)
        let result = await sut.execute(payment)

        guard case .failure(let error) = result else {
            Issue.record("Expected .failure")
            return
        }
        #expect(error == .invalidAmount)
    }

    @Test func repositoryThrows_returnsSaveFailedError() async {
        repo.shouldThrowOnSave = true
        let payment = Payment.make()
        let result = await sut.execute(payment)

        guard case .failure(let error) = result else {
            Issue.record("Expected .failure")
            return
        }
        #expect(error == .saveFailed(""))
    }
}

// MARK: - UpdatePaymentUseCase

@Suite("UpdatePaymentUseCase")
@MainActor
struct UpdatePaymentUseCaseTests {
    let repo = MockPaymentRepository()
    let bus = SpyEventBus()
    let sut: UpdatePaymentUseCase

    init() {
        sut = UpdatePaymentUseCase(paymentRepository: repo, eventBus: bus, log: NullLog())
    }

    @Test func syncedPayment_statusBecomesModified() async {
        let payment = Payment.make(name: "Spotify", amount: 30, syncStatus: .synced)
        repo.payments = [payment]

        let result = await sut.execute(payment)

        guard case .success(let updated) = result else {
            Issue.record("Expected .success")
            return
        }
        #expect(updated.syncStatus == .modified)
        #expect(repo.payments.first { $0.id == payment.id }?.syncStatus == .modified)
    }

    @Test func localPayment_keepsSyncStatus() async {
        let payment = Payment.make(syncStatus: .local)
        repo.payments = [payment]

        let result = await sut.execute(payment)

        guard case .success(let updated) = result else {
            Issue.record("Expected .success")
            return
        }
        #expect(updated.syncStatus == .local)
    }

    @Test func invalidName_returnsValidationError() async {
        let payment = Payment.make(name: "")
        let result = await sut.execute(payment)

        guard case .failure(let error) = result else {
            Issue.record("Expected .failure")
            return
        }
        #expect(error == .invalidName)
        #expect(bus.totalEventCount == 0)
    }

    @Test func publishesUpdatedEvent() async {
        let payment = Payment.make()
        repo.payments = [payment]

        _ = await sut.execute(payment)

        #expect(bus.lastEvent(ofType: PaymentUpdatedEvent.self)?.paymentId == payment.id)
    }

    @Test func groupedPayment_updatesSiblingSharedFields() async {
        let groupId = UUID()
        let penPayment = Payment.make(
            name: "Old Name", amount: 200, currency: .pen,
            category: .servicios, syncStatus: .synced, groupId: groupId
        )
        let usdPayment = Payment.make(
            name: "Old Name", amount: 50, currency: .usd,
            category: .servicios, syncStatus: .local, groupId: groupId
        )
        repo.payments = [penPayment, usdPayment]

        let due = Date(timeIntervalSinceNow: 86400)
        let updated = Payment.make(
            id: penPayment.id, name: "New Name", amount: 300,
            currency: .pen, dueDate: due, category: .tarjetaCredito,
            syncStatus: .synced, groupId: groupId
        )
        _ = await sut.execute(updated)

        let sibling = repo.payments.first { $0.id == usdPayment.id }
        #expect(sibling?.name == "New Name")          // shared: name synced
        #expect(sibling?.dueDate == due)              // shared: due date synced
        #expect(sibling?.category == .tarjetaCredito) // shared: category synced
        #expect(sibling?.amount == 50)                // preserved: own amount
        #expect(sibling?.currency == .usd)            // preserved: own currency
        #expect(sibling?.syncStatus == .local)        // non-synced keeps its status
    }

    @Test func groupedSyncedSibling_becomesModifiedAfterUpdate() async {
        let groupId = UUID()
        let penPayment = Payment.make(
            name: "Bill", amount: 100, currency: .pen,
            category: .servicios, syncStatus: .local, groupId: groupId
        )
        let usdSibling = Payment.make(
            name: "Bill", amount: 80, currency: .usd,
            category: .servicios, syncStatus: .synced, groupId: groupId
        )
        repo.payments = [penPayment, usdSibling]

        _ = await sut.execute(penPayment)

        let sibling = repo.payments.first { $0.id == usdSibling.id }
        #expect(sibling?.syncStatus == .modified)
    }
}

// MARK: - TogglePaymentStatusUseCase

@Suite("TogglePaymentStatusUseCase")
@MainActor
struct TogglePaymentStatusUseCaseTests {
    let repo = MockPaymentRepository()
    let bus = SpyEventBus()
    let sut: TogglePaymentStatusUseCase

    init() {
        sut = TogglePaymentStatusUseCase(paymentRepository: repo, eventBus: bus, log: NullLog())
    }

    @Test func unpaidPayment_becomessPaid() async {
        let payment = Payment.make(isPaid: false)
        repo.payments = [payment]

        let result = await sut.execute(payment)

        guard case .success(let toggled) = result else {
            Issue.record("Expected .success")
            return
        }
        #expect(toggled.isPaid == true)
        #expect(repo.payments.first?.isPaid == true)
    }

    @Test func paidPayment_becomesUnpaid() async {
        let payment = Payment.make(isPaid: true)
        repo.payments = [payment]

        let result = await sut.execute(payment)

        guard case .success(let toggled) = result else {
            Issue.record("Expected .success")
            return
        }
        #expect(toggled.isPaid == false)
    }

    @Test func syncedPayment_statusBecomesModified() async {
        let payment = Payment.make(isPaid: false, syncStatus: .synced)
        repo.payments = [payment]

        let result = await sut.execute(payment)

        guard case .success(let toggled) = result else {
            Issue.record("Expected .success")
            return
        }
        #expect(toggled.syncStatus == .modified)
    }

    @Test func localPayment_keepsSyncStatus() async {
        let payment = Payment.make(isPaid: false, syncStatus: .local)
        repo.payments = [payment]

        let result = await sut.execute(payment)

        guard case .success(let toggled) = result else {
            Issue.record("Expected .success")
            return
        }
        #expect(toggled.syncStatus == .local)
    }

    @Test func toggle_publishesStatusToggledEvent() async {
        let payment = Payment.make(isPaid: false)
        repo.payments = [payment]

        _ = await sut.execute(payment)

        let event = bus.lastEvent(ofType: PaymentStatusToggledEvent.self)
        #expect(event?.paymentId == payment.id)
        #expect(event?.isPaid == true)
    }

    @Test func saveFailure_returnsUpdateFailedError() async {
        repo.shouldThrowOnSave = true
        let payment = Payment.make()

        let result = await sut.execute(payment)

        guard case .failure(let error) = result else {
            Issue.record("Expected .failure")
            return
        }
        #expect(error == .updateFailed(""))
    }
}

// MARK: - DeletePaymentUseCase

@Suite("DeletePaymentUseCase")
@MainActor
struct DeletePaymentUseCaseTests {
    let repo = MockPaymentRepository()
    let bus = SpyEventBus()
    let sut: DeletePaymentUseCase

    init() {
        sut = DeletePaymentUseCase(paymentRepository: repo, eventBus: bus, log: NullLog())
    }

    @Test func existingPayment_deletedAndEventPublished() async {
        let payment = Payment.make()
        repo.payments = [payment]

        let result = await sut.execute(paymentId: payment.id)

        if case .failure(let error) = result { Issue.record("Expected success, got \(error)") }
        #expect(!repo.payments.contains { $0.id == payment.id })
        #expect(bus.lastEvent(ofType: PaymentDeletedEvent.self)?.paymentId == payment.id)
    }

    @Test func deleteFailure_returnsDeleteFailedError() async {
        repo.shouldThrowOnDelete = true
        let payment = Payment.make()
        repo.payments = [payment]

        let result = await sut.execute(paymentId: payment.id)

        guard case .failure(let error) = result else {
            Issue.record("Expected .failure")
            return
        }
        #expect(error == .deleteFailed(""))
        #expect(bus.totalEventCount == 0)
    }

    // MARK: Supabase deletion

    @Test func syncedPayment_deletesFromSupabaseAndLocal() async {
        let payment = Payment.make(syncStatus: .synced)
        repo.payments = [payment]

        let result = await sut.execute(paymentId: payment.id)

        if case .failure(let error) = result { Issue.record("Expected success, got \(error)") }
        #expect(repo.remoteDeletedIds.contains(payment.id), "Should have deleted from Supabase")
        #expect(!repo.payments.contains { $0.id == payment.id }, "Should have deleted locally")
        #expect(bus.lastEvent(ofType: PaymentDeletedEvent.self)?.paymentId == payment.id)
    }

    @Test func modifiedPayment_deletesFromSupabaseAndLocal() async {
        let payment = Payment.make(syncStatus: .modified)
        repo.payments = [payment]

        let result = await sut.execute(paymentId: payment.id)

        if case .failure(let error) = result { Issue.record("Expected success, got \(error)") }
        #expect(repo.remoteDeletedIds.contains(payment.id), "Should have deleted from Supabase")
        #expect(!repo.payments.contains { $0.id == payment.id }, "Should have deleted locally")
    }

    @Test func localPayment_deletesOnlyFromLocal() async {
        let payment = Payment.make(syncStatus: .local)
        repo.payments = [payment]

        let result = await sut.execute(paymentId: payment.id)

        if case .failure(let error) = result { Issue.record("Expected success, got \(error)") }
        #expect(repo.remoteDeletedIds.isEmpty, "Should NOT have called Supabase for a local-only payment")
        #expect(!repo.payments.contains { $0.id == payment.id }, "Should have deleted locally")
    }

    @Test func supabaseFailure_stillDeletesLocally() async {
        repo.shouldThrowOnRemoteDelete = true
        let payment = Payment.make(syncStatus: .synced)
        repo.payments = [payment]

        let result = await sut.execute(paymentId: payment.id)

        // Offline-first: local delete must succeed even if Supabase is unreachable
        if case .failure(let error) = result { Issue.record("Expected success, got \(error)") }
        #expect(!repo.payments.contains { $0.id == payment.id }, "Should have deleted locally despite Supabase failure")
        #expect(bus.lastEvent(ofType: PaymentDeletedEvent.self)?.paymentId == payment.id)
    }
}

// MARK: - UploadLocalChangesUseCase

@Suite("UploadLocalChangesUseCase")
@MainActor
struct UploadLocalChangesUseCaseTests {
    let syncRepo = MockPaymentSyncRepository()
    let sut: UploadLocalChangesUseCase

    init() {
        sut = UploadLocalChangesUseCase(syncRepository: syncRepo, log: NullLog())
    }

    @Test func noPendingPayments_returnsSuccessWithoutUploading() async {
        syncRepo.pendingPayments = []

        let result = await sut.execute()

        if case .failure(let error) = result { Issue.record("Expected success, got \(error)") }
        #expect(syncRepo.uploadCount == 0)
    }

    @Test func pendingPayments_uploadsOnce() async {
        syncRepo.pendingPayments = [Payment.make(), Payment.make()]

        let result = await sut.execute()

        if case .failure(let error) = result { Issue.record("Expected success, got \(error)") }
        #expect(syncRepo.uploadCount == 1)
    }

    @Test func notAuthenticated_returnsAuthError() async {
        syncRepo.shouldThrowOnGetUserId = true
        syncRepo.pendingPayments = [Payment.make()]

        let result = await sut.execute()

        guard case .failure(let error) = result else {
            Issue.record("Expected .failure")
            return
        }
        #expect(error == .notAuthenticated)
    }
}

// MARK: - GetPendingSyncCountUseCase

@Suite("GetPendingSyncCountUseCase")
@MainActor
struct GetPendingSyncCountUseCaseTests {
    let syncRepo = MockPaymentSyncRepository()
    let sut: GetPendingSyncCountUseCase

    init() {
        sut = GetPendingSyncCountUseCase(syncRepository: syncRepo)
    }

    @Test func returnsPendingCount() async {
        syncRepo.pendingPayments = [Payment.make(), Payment.make(), Payment.make()]

        let count = await sut.execute()

        #expect(count == 3)
    }

    @Test func repositoryFailure_returnsZero() async {
        syncRepo.shouldThrowOnGetCount = true

        let count = await sut.execute()

        #expect(count == 0)
    }
}
