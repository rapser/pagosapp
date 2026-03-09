import Foundation
import SwiftData

@MainActor
final class UserProfileSwiftDataDataSource: UserProfileLocalDataSource {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() async throws -> [UserProfileLocalDTO] {
        let descriptor = FetchDescriptor<UserProfileLocalDTO>()
        return try modelContext.fetch(descriptor)
    }

    func save(_ profileDTO: UserProfileLocalDTO) async throws {
        let descriptor = FetchDescriptor<UserProfileLocalDTO>()
        let existingProfiles = try modelContext.fetch(descriptor)

        if let existing = existingProfiles.first(where: { $0.userId == profileDTO.userId }) {
            existing.email = profileDTO.email
            existing.fullName = profileDTO.fullName
            existing.phone = profileDTO.phone
            existing.dateOfBirth = profileDTO.dateOfBirth
            existing.genderRawValue = profileDTO.genderRawValue
            existing.country = profileDTO.country
            existing.city = profileDTO.city
            existing.preferredCurrencyRawValue = profileDTO.preferredCurrencyRawValue
        } else {
            modelContext.insert(profileDTO)
        }

        try modelContext.save()
    }

    func deleteAll(_ profileDTOs: [UserProfileLocalDTO]) async throws {
        let descriptor = FetchDescriptor<UserProfileLocalDTO>()
        let existingProfiles = try modelContext.fetch(descriptor)

        for profileDTO in profileDTOs {
            if let existing = existingProfiles.first(where: { $0.userId == profileDTO.userId }) {
                modelContext.delete(existing)
            }
        }
        try modelContext.save()
    }

    func clear() async throws {
        try modelContext.delete(model: UserProfileLocalDTO.self)
        try modelContext.save()
    }
}
