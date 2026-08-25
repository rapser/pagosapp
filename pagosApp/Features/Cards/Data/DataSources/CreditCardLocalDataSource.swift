import Foundation

@MainActor
protocol CreditCardLocalDataSource {
    func fetchAll() async throws -> [CreditCard]
    func fetch(id: UUID) async throws -> CreditCard?
    func save(_ card: CreditCard) async throws
    func delete(id: UUID) async throws
}
