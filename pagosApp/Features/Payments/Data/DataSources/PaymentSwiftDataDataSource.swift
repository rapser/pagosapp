import Foundation
import SwiftData
import OSLog

@MainActor
final class PaymentSwiftDataDataSource: PaymentLocalDataSource {
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "PaymentSwiftDataDataSource")

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() async throws -> [Payment] {
        logger.debug("📱 Fetching all payments from SwiftData")
        let descriptor = FetchDescriptor<PaymentEntity>()

        do {
            let payments = try modelContext.fetch(descriptor)
            logger.debug("✅ Fetched \(payments.count) payments from SwiftData")
            return payments.map { PaymentMapper.toDomain(from: $0) }
        } catch {
            logger.error("❌ Failed to fetch payments from SwiftData: \(error.localizedDescription)")
            // Return empty array instead of crashing
            return []
        }
    }

    func fetch(id: UUID) async throws -> Payment? {
        logger.debug("📱 Fetching payment by ID: \(id)")
        let descriptor = FetchDescriptor<PaymentEntity>()
        let payments = try modelContext.fetch(descriptor)
        guard let payment = payments.first(where: { $0.id == id }) else {
            logger.debug("❌ Payment not found: \(id)")
            return nil
        }
        logger.debug("✅ Found payment: \(id)")
        return PaymentMapper.toDomain(from: payment)
    }

    func save(_ payment: Payment) async throws {
        logger.debug("💾 Saving payment: \(payment.name)")

        let descriptor = FetchDescriptor<PaymentEntity>()
        let existingPayments = try modelContext.fetch(descriptor)

        if let existing = existingPayments.first(where: { $0.id == payment.id }) {
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
            let newPayment = PaymentMapper.toEntity(from: payment)
            modelContext.insert(newPayment)
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

    func delete(_ payment: Payment) async throws {
        logger.debug("🗑️ Deleting payment: \(payment.name)")

        let descriptor = FetchDescriptor<PaymentEntity>()
        let existingPayments = try modelContext.fetch(descriptor)

        guard let existing = existingPayments.first(where: { $0.id == payment.id }) else {
            logger.debug("⚠️ Payment not found for deletion: \(payment.id)")
            return
        }

        modelContext.delete(existing)
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
            try await delete(payment)
        }

        logger.debug("✅ \(payments.count) payments deleted")
    }

    func clear() async throws {
        logger.info("🗑️ Clearing all payments from SwiftData")

        let descriptor = FetchDescriptor<PaymentEntity>()
        let allPayments = try modelContext.fetch(descriptor)

        for payment in allPayments {
            modelContext.delete(payment)
        }

        try modelContext.save()
        logger.info("✅ All payments cleared (\(allPayments.count) deleted)")
    }
}
