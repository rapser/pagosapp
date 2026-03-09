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
        logger.info("📋 [DATA] PaymentSwiftDataDataSource.fetchAll() called")
        let descriptor = FetchDescriptor<PaymentLocalDTO>()

        do {
            let dtos = try modelContext.fetch(descriptor)
            let payments = dtos.map { PaymentMapper.toDomain(from: $0) }
            logger.info("📋 [DATA] ✅ SwiftData fetch OK: \(dtos.count) DTOs → \(payments.count) Payment(s)")
            return payments
        } catch {
            logger.error("📋 [DATA] ❌ SwiftData fetch failed: \(error.localizedDescription) — returning []")
            return []
        }
    }

    func fetch(id: UUID) async throws -> Payment? {
        let descriptor = FetchDescriptor<PaymentLocalDTO>()
        let payments = try modelContext.fetch(descriptor)
        guard let payment = payments.first(where: { $0.id == id }) else {
            return nil
        }
        return PaymentMapper.toDomain(from: payment)
    }

    func save(_ payment: Payment) async throws {

        let descriptor = FetchDescriptor<PaymentLocalDTO>()
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
        } else {
            let newPayment = PaymentMapper.toLocalDTO(from: payment)
            modelContext.insert(newPayment)
        }

        try modelContext.save()
    }

    func saveAll(_ payments: [Payment]) async throws {
        guard !payments.isEmpty else {
            return
        }

        for payment in payments {
            try await save(payment)
        }
    }

    func delete(_ payment: Payment) async throws {

        let descriptor = FetchDescriptor<PaymentLocalDTO>()
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

        let descriptor = FetchDescriptor<PaymentLocalDTO>()
        let allPayments = try modelContext.fetch(descriptor)

        for payment in allPayments {
            modelContext.delete(payment)
        }

        try modelContext.save()
        logger.info("✅ All payments cleared (\(allPayments.count) deleted)")
    }
}
