import Foundation
import SwiftData

@MainActor
final class PaymentSwiftDataDataSource: PaymentLocalDataSource {
    private static let logCategory = "PaymentSwiftDataDataSource"

    private let modelContext: ModelContext
    private let log: DomainLogWriter

    init(modelContext: ModelContext, log: DomainLogWriter) {
        self.modelContext = modelContext
        self.log = log
    }

    func fetchAll() async throws -> [Payment] {
        let descriptor = FetchDescriptor<PaymentLocalDTO>(
            sortBy: [SortDescriptor(\PaymentLocalDTO.dueDate, order: .forward)]
        )
        do {
            let payments = try modelContext.fetch(descriptor).map { PaymentMapper.toDomain(from: $0) }
            return payments
        } catch {
            log.error("Failed to fetch payments from SwiftData: \(error.localizedDescription)", category: Self.logCategory)
            return []
        }
    }

    func fetch(id: UUID) async throws -> Payment? {
        // Optimized: use predicate to filter at database level instead of loading all
        let predicate = #Predicate<PaymentLocalDTO> { dto in 
            dto.id == id
        }
        var descriptor = FetchDescriptor<PaymentLocalDTO>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        let payments = try modelContext.fetch(descriptor)
        return payments.first.map { PaymentMapper.toDomain(from: $0) }
    }

    func save(_ payment: Payment) async throws {
        // Optimized: use predicate to check for existing payment
        let paymentId = payment.id
        let predicate = #Predicate<PaymentLocalDTO> { dto in 
            dto.id == paymentId
        }
        var descriptor = FetchDescriptor<PaymentLocalDTO>(predicate: predicate)
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
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
        guard !payments.isEmpty else { return }

        // Optimized: batch fetch existing IDs to minimize DB round trips
        let paymentIds = payments.map { $0.id }
        let predicate = #Predicate<PaymentLocalDTO> { dto in
            paymentIds.contains(dto.id)
        }
        let descriptor = FetchDescriptor<PaymentLocalDTO>(predicate: predicate)
        let existingDTOs = try modelContext.fetch(descriptor)
        let existingById = Dictionary(uniqueKeysWithValues: existingDTOs.map { ($0.id, $0) })

        for payment in payments {
            if let existing = existingById[payment.id] {
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
                let newDTO = PaymentMapper.toLocalDTO(from: payment)
                modelContext.insert(newDTO)
            }
        }

        try modelContext.save()
    }

    func delete(_ payment: Payment) async throws {
        // Optimized: use predicate to find specific payment
        let paymentId = payment.id
        let predicate = #Predicate<PaymentLocalDTO> { dto in 
            dto.id == paymentId
        }
        var descriptor = FetchDescriptor<PaymentLocalDTO>(predicate: predicate)
        descriptor.fetchLimit = 1

        guard let existing = try modelContext.fetch(descriptor).first else { return }

        modelContext.delete(existing)
        try modelContext.save()
    }

    func deleteAll(_ payments: [Payment]) async throws {
        guard !payments.isEmpty else { return }
        
        // Optimized: batch delete by IDs
        let paymentIds = payments.map { $0.id }
        let predicate = #Predicate<PaymentLocalDTO> { dto in
            paymentIds.contains(dto.id)
        }
        let descriptor = FetchDescriptor<PaymentLocalDTO>(predicate: predicate)
        let existingDTOs = try modelContext.fetch(descriptor)
        
        for dto in existingDTOs {
            modelContext.delete(dto)
        }
        
        try modelContext.save()
    }

    func clear() async throws {
        let descriptor = FetchDescriptor<PaymentLocalDTO>()
        let allPayments = try modelContext.fetch(descriptor)
        for payment in allPayments {
            modelContext.delete(payment)
        }
        try modelContext.save()
    }
}
