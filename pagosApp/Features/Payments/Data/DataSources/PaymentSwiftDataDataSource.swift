//
//  PaymentSwiftDataDataSource.swift
//  pagosApp
//
//  SwiftData implementation of PaymentLocalDataSource
//  Clean Architecture - Data Layer
//

import Foundation
import SwiftData
import OSLog

/// SwiftData implementation for payment local operations
@MainActor
final class PaymentSwiftDataDataSource: PaymentLocalDataSource {
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "PaymentSwiftDataDataSource")

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch Operations

    func fetchAll() async throws -> [Payment] {
        logger.debug("📱 Fetching all payments from SwiftData")
        let descriptor = FetchDescriptor<Payment>()
        let payments = try modelContext.fetch(descriptor)
        logger.debug("✅ Fetched \(payments.count) payments from SwiftData")
        return payments
    }

    func fetch(id: UUID) async throws -> Payment? {
        logger.debug("📱 Fetching payment by ID: \(id)")
        let descriptor = FetchDescriptor<Payment>()
        let payments = try modelContext.fetch(descriptor)
        let payment = payments.first(where: { $0.id == id })

        if payment != nil {
            logger.debug("✅ Found payment: \(id)")
        } else {
            logger.debug("❌ Payment not found: \(id)")
        }

        return payment
    }

    // MARK: - Save Operations

    func save(_ payment: Payment) async throws {
        logger.debug("💾 Saving payment: \(payment.name)")

        // Check if payment already exists
        let descriptor = FetchDescriptor<Payment>()
        let existingPayments = try modelContext.fetch(descriptor)

        if let existing = existingPayments.first(where: { $0.id == payment.id }) {
            // Update existing payment
            existing.name = payment.name
            existing.amount = payment.amount
            existing.currency = payment.currency
            existing.dueDate = payment.dueDate
            existing.isPaid = payment.isPaid
            existing.category = payment.category
            existing.eventIdentifier = payment.eventIdentifier
            existing.syncStatus = payment.syncStatus
            existing.lastSyncedAt = payment.lastSyncedAt
            logger.debug("🔄 Updated existing payment: \(payment.name)")
        } else {
            // Insert new payment
            modelContext.insert(payment)
            logger.debug("➕ Inserted new payment: \(payment.name)")
        }

        try modelContext.save()
        logger.debug("✅ Payment saved: \(payment.name)")
    }

    func saveAll(_ payments: [Payment]) async throws {
        guard !payments.isEmpty else {
            logger.debug("⚠️ No payments to save")
            return
        }

        logger.debug("💾 Saving \(payments.count) payments")

        for payment in payments {
            try await save(payment)
        }

        logger.debug("✅ \(payments.count) payments saved")
    }

    // MARK: - Delete Operations

    func delete(_ payment: Payment) async throws {
        logger.debug("🗑️ Deleting payment: \(payment.name)")
        modelContext.delete(payment)
        try modelContext.save()
        logger.debug("✅ Payment deleted: \(payment.name)")
    }

    func deleteAll(_ payments: [Payment]) async throws {
        guard !payments.isEmpty else {
            logger.debug("⚠️ No payments to delete")
            return
        }

        logger.debug("🗑️ Deleting \(payments.count) payments")

        for payment in payments {
            modelContext.delete(payment)
        }

        try modelContext.save()
        logger.debug("✅ \(payments.count) payments deleted")
    }

    func clear() async throws {
        logger.info("🗑️ Clearing all payments from SwiftData")

        let descriptor = FetchDescriptor<Payment>()
        let allPayments = try modelContext.fetch(descriptor)

        for payment in allPayments {
            modelContext.delete(payment)
        }

        try modelContext.save()
        logger.info("✅ All payments cleared (\(allPayments.count) deleted)")
    }
}
