import Foundation

protocol UserProfileLocalDataSource {
    func fetchAll() async throws -> [UserProfileLocalDTO]
    func save(_ profileDTO: UserProfileLocalDTO) async throws
    func deleteAll(_ profileDTOs: [UserProfileLocalDTO]) async throws
    func clear() async throws
}
