import Foundation
import SwiftData

@MainActor
final class CreditCardSwiftDataDataSource: CreditCardLocalDataSource {
    private static let logCategory = "CreditCardSwiftDataDataSource"

    private let modelContext: ModelContext
    private let log: DomainLogWriter

    init(modelContext: ModelContext, log: DomainLogWriter) {
        self.modelContext = modelContext
        self.log = log
    }

    func fetchAll() async throws -> [CreditCard] {
        let descriptor = FetchDescriptor<CreditCardLocalDTO>(
            sortBy: [SortDescriptor(\CreditCardLocalDTO.createdAt, order: .reverse)]
        )
        do {
            return try modelContext.fetch(descriptor).map { CreditCardMapper.toDomain(from: $0) }
        } catch {
            log.error("Failed to fetch cards from SwiftData: \(error.localizedDescription)", category: Self.logCategory)
            return []
        }
    }

    func fetch(id: UUID) async throws -> CreditCard? {
        let predicate = #Predicate<CreditCardLocalDTO> { dto in
            dto.id == id
        }
        var descriptor = FetchDescriptor<CreditCardLocalDTO>(predicate: predicate)
        descriptor.fetchLimit = 1

        let cards = try modelContext.fetch(descriptor)
        return cards.first.map { CreditCardMapper.toDomain(from: $0) }
    }

    func save(_ card: CreditCard) async throws {
        let cardId = card.id
        let predicate = #Predicate<CreditCardLocalDTO> { dto in
            dto.id == cardId
        }
        var descriptor = FetchDescriptor<CreditCardLocalDTO>(predicate: predicate)
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.bank = card.bank
            existing.customBankName = card.customBankName
            existing.brand = card.brand
            existing.last4 = card.last4
            existing.expirationMonth = card.expirationMonth
            existing.expirationYear = card.expirationYear
        } else {
            modelContext.insert(CreditCardMapper.toLocalDTO(from: card))
        }

        try modelContext.save()
    }

    func delete(id: UUID) async throws {
        let predicate = #Predicate<CreditCardLocalDTO> { dto in
            dto.id == id
        }
        var descriptor = FetchDescriptor<CreditCardLocalDTO>(predicate: predicate)
        descriptor.fetchLimit = 1

        guard let existing = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(existing)
        try modelContext.save()
    }
}
