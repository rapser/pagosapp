import Foundation

protocol PaymentLocalDataSource {
    func fetchAll() async throws -> [PaymentEntity]
    func fetch(id: UUID) async throws -> PaymentEntity?
    func save(_ payment: PaymentEntity) async throws
    func saveAll(_ payments: [PaymentEntity]) async throws
    func delete(_ payment: PaymentEntity) async throws
    func deleteAll(_ payments: [PaymentEntity]) async throws
    func clear() async throws
}
