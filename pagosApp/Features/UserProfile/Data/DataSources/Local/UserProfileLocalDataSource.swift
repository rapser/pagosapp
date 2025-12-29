import Foundation

protocol UserProfileLocalDataSource {
    func fetchAll() async throws -> [UserProfileEntity]
    func save(_ profile: UserProfileEntity) async throws
    func deleteAll(_ profiles: [UserProfileEntity]) async throws
    func clear() async throws
}
