import Foundation

protocol PaymentLocalDataSource {
    func fetchAll() async throws -> [Payment]
    func fetch(id: UUID) async throws -> Payment?
    func save(_ payment: Payment) async throws
    func saveAll(_ payments: [Payment]) async throws
    func delete(_ payment: Payment) async throws
    func deleteAll(_ payments: [Payment]) async throws
    func clear() async throws
    /// Hides a payment from all fetches while keeping a tombstone so the deletion can be pushed to Supabase later.
    func markPendingDeletion(id: UUID) async throws
    func fetchPendingDeletionIds() async throws -> [UUID]
}
