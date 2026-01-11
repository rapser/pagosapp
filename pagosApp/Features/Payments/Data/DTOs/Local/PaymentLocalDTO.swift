//
//  PaymentLocalDTO.swift
//  pagosApp
//
//  SwiftData model for local persistence
//  Clean Architecture - Data Layer (Local DTO)
//

import Foundation
import SwiftData

/// Local DTO for Payment persistence with SwiftData
/// Clean Architecture: DTOs handle serialization, Domain models are pure
@Model
final class PaymentLocalDTO {
    @Attribute(.unique) var id: UUID
    var name: String
    var amount: Decimal
    var currencyRawValue: String
    var dueDate: Date
    var isPaid: Bool
    var categoryRawValue: String
    var eventIdentifier: String?
    var syncStatusRawValue: String
    var lastSyncedAt: Date?
    var groupId: UUID?

    init(
        name: String,
        amount: Decimal,
        dueDate: Date,
        isPaid: Bool = false,
        category: PaymentCategory,
        currency: Currency = .pen,
        groupId: UUID? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.currencyRawValue = currency.rawValue
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.categoryRawValue = category.rawValue
        self.eventIdentifier = nil
        self.syncStatusRawValue = SyncStatus.local.rawValue
        self.lastSyncedAt = nil
        self.groupId = groupId
    }

    /// Full initializer for syncing with backend
    init(
        id: UUID,
        name: String,
        amount: Decimal,
        currency: Currency = .pen,
        dueDate: Date,
        isPaid: Bool,
        category: PaymentCategory,
        eventIdentifier: String?,
        syncStatus: SyncStatus = .local,
        lastSyncedAt: Date? = nil,
        groupId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.currencyRawValue = currency.rawValue
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.categoryRawValue = category.rawValue
        self.eventIdentifier = eventIdentifier
        self.syncStatusRawValue = syncStatus.rawValue
        self.lastSyncedAt = lastSyncedAt
        self.groupId = groupId
    }

    // MARK: - Computed Properties

    var currency: Currency {
        get { Currency(rawValue: currencyRawValue) ?? .pen }
        set { currencyRawValue = newValue.rawValue }
    }

    var category: PaymentCategory {
        get { PaymentCategory(rawValue: categoryRawValue) ?? .otro }
        set { categoryRawValue = newValue.rawValue }
    }

    var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRawValue) ?? .local }
        set { syncStatusRawValue = newValue.rawValue }
    }
}
