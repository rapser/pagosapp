//
//  Payment.swift
//  pagosApp
//
//  Domain entity for Payment (Sendable, thread-safe)
//  Clean Architecture: Domain layer models are Sendable and independent of persistence
//

import Foundation

/// Sendable domain entity for Payment
/// This is the thread-safe version used in business logic
/// Clean Architecture: Domain models are pure, no UI dependencies
struct Payment: Sendable {
    let id: UUID
    let name: String
    let amount: Decimal  // Changed from Double for precision
    let currency: Currency
    let dueDate: Date
    var isPaid: Bool  // Mutable for status updates
    let category: PaymentCategory
    let eventIdentifier: String?
    let syncStatus: SyncStatus
    let lastSyncedAt: Date?
    let groupId: UUID?  // Links dual-currency credit card payments (PEN + USD)
}

// MARK: - Mapper Extensions
// NOTE: Mappers will be moved to PaymentMapper.swift after renaming SwiftData model
