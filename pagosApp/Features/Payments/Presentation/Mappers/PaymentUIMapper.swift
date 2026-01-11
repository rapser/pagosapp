//
//  PaymentUIMapper.swift
//  pagosApp
//
//  Mapper implementation for Payment Domain ↔ PaymentUI Presentation
//  Clean Architecture - Presentation Layer Mapper Implementation
//

import Foundation

/// Mapper for converting between Payment (Domain) and PaymentUI (Presentation)
struct PaymentUIMapper: PaymentUIMapping {
    func toUI(_ domain: Payment) -> PaymentUI {
        PaymentUI(
            id: domain.id,
            name: domain.name,
            amount: NSDecimalNumber(decimal: domain.amount).doubleValue,
            currency: domain.currency,
            dueDate: domain.dueDate,
            isPaid: domain.isPaid,
            category: domain.category,
            eventIdentifier: domain.eventIdentifier,
            syncStatus: domain.syncStatus,
            lastSyncedAt: domain.lastSyncedAt,
            groupId: domain.groupId
        )
    }

    func toDomain(_ ui: PaymentUI) -> Payment {
        Payment(
            id: ui.id,
            name: ui.name,
            amount: Decimal(ui.amount),
            currency: ui.currency,
            dueDate: ui.dueDate,
            isPaid: ui.isPaid,
            category: ui.category,
            eventIdentifier: ui.eventIdentifier,
            syncStatus: ui.syncStatus,
            lastSyncedAt: ui.lastSyncedAt,
            groupId: ui.groupId
        )
    }

    func toUI(_ domains: [Payment]) -> [PaymentUI] {
        domains.map { toUI($0) }
    }

    func toDomain(_ uis: [PaymentUI]) -> [Payment] {
        uis.map { toDomain($0) }
    }
}
