import Foundation

protocol PaymentLocalDataSource {
    func fetchAll() async throws -> [Payment]
    func fetch(id: UUID) async throws -> Payment?
    func save(_ payment: Payment) async throws
    func saveAll(_ payments: [Payment]) async throws
    func delete(_ payment: Payment) async throws
    func deleteAll(_ payments: [Payment]) async throws
    func clear() async throws
}
