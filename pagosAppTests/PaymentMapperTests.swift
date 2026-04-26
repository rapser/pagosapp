//
//  PaymentMapperTests.swift
//  pagosAppTests
//

import Foundation
import Testing
@testable import pagosApp

struct PaymentMapperTests {

    @Test func localDTORoundTripPreservesIdentityAndAmounts() {
        let id = UUID()
        let groupId = UUID()
        let due = Date(timeIntervalSince1970: 1_700_000_000)
        let lastSync = Date(timeIntervalSince1970: 1_700_000_100)

        let dto = PaymentLocalDTO(
            id: id,
            name: "Rent",
            amount: Decimal(string: "99.50")!,
            currency: .usd,
            dueDate: due,
            isPaid: false,
            category: .servicios,
            eventIdentifier: "evt-1",
            syncStatus: .modified,
            lastSyncedAt: lastSync,
            groupId: groupId
        )

        let domain = PaymentMapper.toDomain(from: dto)
        #expect(domain.id == id)
        #expect(domain.name == "Rent")
        #expect(domain.amount == Decimal(string: "99.50"))
        #expect(domain.currency == .usd)
        #expect(domain.dueDate == due)
        #expect(domain.isPaid == false)
        #expect(domain.category == .servicios)
        #expect(domain.eventIdentifier == "evt-1")
        #expect(domain.syncStatus == .modified)
        #expect(domain.lastSyncedAt == lastSync)
        #expect(domain.groupId == groupId)

        let back = PaymentMapper.toLocalDTO(from: domain)
        #expect(back.id == id)
        #expect(back.name == "Rent")
        #expect(back.amount == Decimal(string: "99.50"))
        #expect(back.currency == .usd)
    }

    @Test func remoteDTOUsesDefaultsForUnknownCategoryAndCurrency() {
        let id = UUID()
        let userId = UUID()
        let due = Date()

        let dto = PaymentDTO(
            id: id,
            userId: userId,
            name: "X",
            amount: 10,
            currency: "not_a_currency",
            dueDate: due,
            isPaid: true,
            category: "not_a_category",
            eventIdentifier: nil,
            groupId: nil,
            createdAt: nil,
            updatedAt: nil
        )

        let payment = PaymentMapper.toDomain(from: dto)
        #expect(payment.category == .otro)
        #expect(payment.currency == .pen)
        #expect(payment.name == "X")
        #expect(payment.syncStatus == .synced)
    }

    @Test func domainToRemoteDTOConvertsAmountAndUserId() {
        let id = UUID()
        let userId = UUID()
        let due = Date()

        let payment = Payment(
            id: id,
            name: "A",
            amount: Decimal(25.5),
            currency: .pen,
            dueDate: due,
            isPaid: false,
            category: .suscripcion,
            eventIdentifier: nil,
            syncStatus: .local,
            lastSyncedAt: nil,
            groupId: nil
        )

        let dto = PaymentMapper.toRemoteDTO(from: payment, userId: userId)
        #expect(dto.id == id)
        #expect(dto.userId == userId)
        #expect(dto.name == "A")
        #expect(dto.amount == 25.5)
        #expect(dto.currency == Currency.pen.rawValue)
        #expect(dto.category == PaymentCategory.suscripcion.rawValue)
    }
}
