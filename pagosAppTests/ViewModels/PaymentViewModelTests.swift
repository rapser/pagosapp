//
//  PaymentViewModelTests.swift
//  pagosAppTests
//
//  Unit tests for Payment ViewModels (PaymentsListViewModel, AddPaymentViewModel, EditPaymentViewModel).
//

import Foundation
import Testing
@testable import pagosApp

// MARK: - PaymentsListViewModel

@Suite("PaymentsListViewModel")
@MainActor
struct PaymentsListViewModelTests {
    let repo = MockPaymentRepository()
    let bus = SpyEventBus()
    let mapper = PaymentUIMapper()
    let sut: PaymentsListViewModel

    init() {
        let getAllUseCase = GetAllPaymentsUseCase(paymentRepository: repo, log: NullLog())
        let deleteUseCase = DeletePaymentUseCase(paymentRepository: repo, eventBus: bus, log: NullLog())
        let toggleUseCase = TogglePaymentStatusUseCase(paymentRepository: repo, eventBus: bus, log: NullLog())
        sut = PaymentsListViewModel(
            getAllPaymentsUseCase: getAllUseCase,
            deletePaymentUseCase: deleteUseCase,
            togglePaymentStatusUseCase: toggleUseCase,
            eventBus: bus,
            mapper: mapper
        )
    }

    @Test func fetchPayments_populatesList() async {
        repo.payments = [Payment.make(name: "Netflix"), Payment.make(name: "Spotify"), Payment.make(name: "Disney")]

        await sut.fetchPayments()

        #expect(sut.payments.count == 3)
    }

    @Test func fetchPayments_emptyRepo_resultInEmptyList() async {
        repo.payments = []

        await sut.fetchPayments()

        #expect(sut.payments.isEmpty)
    }

    @Test func deletePayment_optimisticallyRemovesFromList() async {
        let payment = Payment.make(name: "Netflix")
        repo.payments = [payment]
        await sut.fetchPayments()

        let paymentUI = sut.payments.first!
        await sut.deletePayment(paymentUI)

        #expect(!sut.payments.contains { $0.id == payment.id })
        #expect(!repo.payments.contains { $0.id == payment.id })
    }

    @Test func deletePayment_repoFailure_revertsOptimisticUpdate() async {
        let payment = Payment.make(name: "Netflix")
        repo.payments = [payment]
        await sut.fetchPayments()
        repo.shouldThrowOnDelete = true

        let paymentUI = sut.payments.first!
        await sut.deletePayment(paymentUI)

        #expect(sut.payments.contains { $0.id == payment.id })
        #expect(sut.errorMessage != nil)
    }

    @Test func togglePaymentStatus_updatesIsPaidInRepo() async {
        let payment = Payment.make(name: "Netflix", isPaid: false)
        repo.payments = [payment]
        await sut.fetchPayments()

        let paymentUI = sut.payments.first!
        await sut.togglePaymentStatus(paymentUI)

        #expect(repo.payments.first { $0.id == payment.id }?.isPaid == true)
    }

    @Test func togglePaymentStatus_optimisticallyUpdatesUI() async {
        let payment = Payment.make(isPaid: false)
        repo.payments = [payment]
        await sut.fetchPayments()

        let paymentUI = sut.payments.first!
        await sut.togglePaymentStatus(paymentUI)

        #expect(sut.payments.first { $0.id == payment.id }?.isPaid == true)
    }

    @Test func paymentEvent_triggersSilentRefresh() async {
        repo.payments = [Payment.make(name: "Netflix")]
        await sut.fetchPayments()
        #expect(sut.payments.count == 1)

        await Task.yield()
        repo.payments.append(Payment.make(name: "Spotify"))
        bus.publish(PaymentCreatedEvent(paymentId: UUID()))
        try? await Task.sleep(nanoseconds: 50_000_000)

        #expect(sut.payments.count == 2)
    }
}

// MARK: - AddPaymentViewModel

@Suite("AddPaymentViewModel")
@MainActor
struct AddPaymentViewModelTests {
    let repo = MockPaymentRepository()
    let bus = SpyEventBus()
    let sut: AddPaymentViewModel

    init() {
        let createUseCase = CreatePaymentUseCase(paymentRepository: repo, eventBus: bus, log: NullLog())
        sut = AddPaymentViewModel(createPaymentUseCase: createUseCase, mapper: PaymentUIMapper())
    }

    @Test func emptyName_isNotValid() {
        sut.name = ""
        sut.amount = "100.00"

        #expect(sut.isValid == false)
    }

    @Test func validNameAndAmount_isValid() {
        sut.name = "Netflix"
        sut.amount = "100.00"
        sut.category = .servicios

        #expect(sut.isValid == true)
    }

    @Test func tcWithNeitherAmount_isNotValid() {
        sut.name = "TC"
        sut.category = .tarjetaCredito
        sut.amount = ""
        sut.amountUSD = ""

        #expect(sut.isValid == false)
    }

    @Test func tcWithOnlyPEN_isValid() {
        sut.name = "TC"
        sut.category = .tarjetaCredito
        sut.amount = "500.00"
        sut.amountUSD = ""

        #expect(sut.isValid == true)
    }

    @Test func savePayment_singleCurrency_createsOnePayment() async {
        sut.name = "Netflix"
        sut.amount = "100.00"
        sut.category = .servicios

        await sut.savePayment()

        #expect(repo.payments.count == 1)
        #expect(repo.payments.first?.name == "Netflix")
    }

    @Test func savePayment_dualCurrency_createsTwoLinkedPayments() async {
        sut.name = "TC Visa"
        sut.category = .tarjetaCredito
        sut.amount = "500.00"
        sut.amountUSD = "100.00"

        await sut.savePayment()

        #expect(repo.payments.count == 2)
        let penPayment = repo.payments.first { $0.currency == .pen }
        let usdPayment = repo.payments.first { $0.currency == .usd }
        #expect(penPayment?.groupId != nil)
        #expect(penPayment?.groupId == usdPayment?.groupId, "Both payments must share the same groupId")
    }

    @Test func savePayment_success_clearsForm() async {
        sut.name = "Netflix"
        sut.amount = "100.00"

        await sut.savePayment()

        #expect(sut.name.isEmpty)
        #expect(sut.amount.isEmpty)
    }

    @Test func savePayment_repoFailure_setsErrorMessage() async {
        repo.shouldThrowOnSave = true
        sut.name = "Netflix"
        sut.amount = "100.00"

        await sut.savePayment()

        #expect(sut.errorMessage != nil)
    }
}

// MARK: - EditPaymentViewModel

@Suite("EditPaymentViewModel")
@MainActor
struct EditPaymentViewModelTests {
    let repo = MockPaymentRepository()
    let bus = SpyEventBus()
    let mapper = PaymentUIMapper()

    private func makeSUT(payment: PaymentUI, otherPayment: PaymentUI? = nil) -> EditPaymentViewModel {
        let createUseCase = CreatePaymentUseCase(paymentRepository: repo, eventBus: bus, log: NullLog())
        let updateUseCase = UpdatePaymentUseCase(paymentRepository: repo, eventBus: bus, log: NullLog())
        let toggleUseCase = TogglePaymentStatusUseCase(paymentRepository: repo, eventBus: bus, log: NullLog())
        return EditPaymentViewModel(
            payment: payment,
            otherPayment: otherPayment,
            createPaymentUseCase: createUseCase,
            updatePaymentUseCase: updateUseCase,
            togglePaymentStatusUseCase: toggleUseCase,
            mapper: mapper
        )
    }

    @Test func singleTCPENPayment_isDualCurrencyTrue_isGroupedFalse() {
        let penPayment = PaymentUI.make(currency: .pen, category: .tarjetaCredito)
        let sut = makeSUT(payment: penPayment)

        #expect(sut.isDualCurrencyPayment == true)
        #expect(sut.isGroupedDualCurrency == false)
        #expect(!sut.amount.isEmpty)
        #expect(sut.amountUSD.isEmpty)
    }

    @Test func groupedTCPayment_isDualCurrencyTrue_isGroupedTrue() {
        let groupId = UUID()
        let penPayment = PaymentUI.make(currency: .pen, category: .tarjetaCredito, groupId: groupId)
        let usdPayment = PaymentUI.make(currency: .usd, category: .tarjetaCredito, groupId: groupId)
        let sut = makeSUT(payment: penPayment, otherPayment: usdPayment)

        #expect(sut.isDualCurrencyPayment == true)
        #expect(sut.isGroupedDualCurrency == true)
        #expect(!sut.amount.isEmpty)
        #expect(!sut.amountUSD.isEmpty)
    }

    @Test func nameChange_detectsHasChanges() {
        let payment = PaymentUI.make(name: "Netflix")
        let sut = makeSUT(payment: payment)

        sut.name = "Netflix Premium"

        #expect(sut.hasChanges == true)
    }

    @Test func noChanges_hasChangesFalse() {
        let payment = PaymentUI.make(name: "Netflix", amount: 100.0)
        let sut = makeSUT(payment: payment)

        // init pre-populates fields; nothing modified
        #expect(sut.hasChanges == false)
    }

    @Test func singleTCPayment_addingUSDAmount_detectsHasChanges() {
        let penPayment = PaymentUI.make(amount: 100.0, currency: .pen, category: .tarjetaCredito)
        let sut = makeSUT(payment: penPayment)

        sut.amountUSD = "50.00"

        #expect(sut.hasChanges == true)
    }

    @Test func resetChanges_restoresOriginalValues() {
        let payment = PaymentUI.make(name: "Netflix", amount: 100.0)
        let sut = makeSUT(payment: payment)

        sut.name = "Changed Name"
        sut.amount = "999.00"
        sut.resetChanges()

        #expect(sut.name == "Netflix")
        #expect(sut.amount == "100.00")
        #expect(sut.hasChanges == false)
    }

    @Test func saveChanges_singlePayment_callsUpdateUseCase() async {
        let payment = Payment.make(name: "Netflix", amount: 100)
        repo.payments = [payment]
        let sut = makeSUT(payment: mapper.toUI(payment))

        sut.name = "Netflix Premium"

        await sut.saveChanges()

        #expect(repo.payments.first { $0.id == payment.id }?.name == "Netflix Premium")
    }

    @Test func saveChanges_upgradingToGrouped_createsTwoLinkedPayments() async {
        let payment = Payment.make(name: "TC", amount: 100, currency: .pen, category: .tarjetaCredito)
        repo.payments = [payment]
        let sut = makeSUT(payment: mapper.toUI(payment))

        sut.amountUSD = "50.00"

        await sut.saveChanges()

        #expect(repo.payments.count == 2)
        let penSaved = repo.payments.first { $0.currency == .pen }
        let usdSaved = repo.payments.first { $0.currency == .usd }
        #expect(penSaved?.groupId != nil)
        #expect(penSaved?.groupId == usdSaved?.groupId, "Both payments must share the same groupId")
    }
}
