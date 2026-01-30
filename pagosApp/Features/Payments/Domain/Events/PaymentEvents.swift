//
//  PaymentEvents.swift
//  pagosApp
//
//  Domain events for Payment feature
//  Clean Architecture - Domain Layer
//

import Foundation

/// Event emitted when payments have been synced successfully
struct PaymentsSyncedEvent: DomainEvent {
    let timestamp: Date
    let syncedCount: Int

    init(syncedCount: Int, timestamp: Date = Date()) {
        self.syncedCount = syncedCount
        self.timestamp = timestamp
    }
}

/// Event emitted when a payment has been created
struct PaymentCreatedEvent: DomainEvent {
    let timestamp: Date
    let paymentId: UUID

    init(paymentId: UUID, timestamp: Date = Date()) {
        self.paymentId = paymentId
        self.timestamp = timestamp
    }
}

/// Event emitted when a payment has been updated
struct PaymentUpdatedEvent: DomainEvent {
    let timestamp: Date
    let paymentId: UUID

    init(paymentId: UUID, timestamp: Date = Date()) {
        self.paymentId = paymentId
        self.timestamp = timestamp
    }
}

/// Event emitted when a payment has been deleted
struct PaymentDeletedEvent: DomainEvent {
    let timestamp: Date
    let paymentId: UUID

    init(paymentId: UUID, timestamp: Date = Date()) {
        self.paymentId = paymentId
        self.timestamp = timestamp
    }
}

/// Event emitted when a payment status has been toggled
struct PaymentStatusToggledEvent: DomainEvent {
    let timestamp: Date
    let paymentId: UUID
    let isPaid: Bool

    init(paymentId: UUID, isPaid: Bool, timestamp: Date = Date()) {
        self.paymentId = paymentId
        self.isPaid = isPaid
        self.timestamp = timestamp
    }
}
