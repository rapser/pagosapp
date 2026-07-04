//
//  HistoryViewModelTests.swift
//  pagosAppTests
//
//  Unit tests for PaymentHistoryViewModel.
//

import Foundation
import Testing
@testable import pagosApp

@Suite("PaymentHistoryViewModel")
@MainActor
struct PaymentHistoryViewModelTests {
    let repo = MockPaymentRepository()
    let bus = SpyEventBus()
    let mapper = PaymentUIMapper()
    let sut: PaymentHistoryViewModel

    init() {
        let historyRepository = HistoryRepositoryImpl(paymentRepository: repo, log: NullLog())
        let useCase = GetPaymentHistoryUseCase(historyRepository: historyRepository)
        sut = PaymentHistoryViewModel(
            getPaymentHistoryUseCase: useCase,
            eventBus: bus,
            mapper: mapper
        )
    }

    @Test func paymentEvent_triggersRefresh() async {
        repo.payments = [Payment.make(name: "Netflix", isPaid: true)]
        await sut.fetchPayments()
        #expect(sut.allPayments.count == 1)

        await Task.yield()
        repo.payments.append(Payment.make(name: "Spotify", isPaid: true))
        bus.publish(PaymentCreatedEvent(paymentId: UUID()))
        try? await Task.sleep(nanoseconds: 50_000_000)

        #expect(sut.allPayments.count == 2)
    }
}
