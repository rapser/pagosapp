//
//  PaymentEntity.swift
//  pagosApp
//
//  Domain entity for Payment (Sendable, thread-safe)
//  Clean Architecture: Domain layer models are Sendable and independent of persistence
//

import Foundation

/// Sendable domain entity for Payment
/// This is the thread-safe version used in business logic
struct PaymentEntity: Sendable, Identifiable {
    let id: UUID
    let name: String
    let amount: Double
    let currency: Currency
    let dueDate: Date
    var isPaid: Bool  // Mutable for status updates
    let category: PaymentCategory
    let eventIdentifier: String?
    let syncStatus: SyncStatus
    let lastSyncedAt: Date?
}

// MARK: - Mapper Extensions

extension PaymentEntity {
    /// Convert from SwiftData model to domain entity
    init(from model: Payment) {
        self.id = model.id
        self.name = model.name
        self.amount = model.amount
        self.currency = model.currency
        self.dueDate = model.dueDate
        self.isPaid = model.isPaid
        self.category = model.category
        self.eventIdentifier = model.eventIdentifier
        self.syncStatus = model.syncStatus
        self.lastSyncedAt = model.lastSyncedAt
    }
    
    /// Convert from domain entity to SwiftData model
    func toModel() -> Payment {
        return Payment(
            id: id,
            name: name,
            amount: amount,
            currency: currency,
            dueDate: dueDate,
            isPaid: isPaid,
            category: category,
            eventIdentifier: eventIdentifier,
            syncStatus: syncStatus,
            lastSyncedAt: lastSyncedAt
        )
    }
}

// MARK: - Convenience Extensions

extension Array where Element == Payment {
    /// Convert array of SwiftData models to domain entities
    func toEntities() -> [PaymentEntity] {
        map { PaymentEntity(from: $0) }
    }
}

extension Array where Element == PaymentEntity {
    /// Convert array of domain entities to SwiftData models
    func toModels() -> [Payment] {
        map { $0.toModel() }
    }
}
