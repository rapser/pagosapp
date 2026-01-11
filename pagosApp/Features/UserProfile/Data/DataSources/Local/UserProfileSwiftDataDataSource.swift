import Foundation
import SwiftData
import OSLog

@MainActor
final class UserProfileSwiftDataDataSource: UserProfileLocalDataSource {
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "UserProfileSwiftDataDataSource")

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() async throws -> [UserProfileLocalDTO] {
        logger.debug("📱 Fetching all profiles from SwiftData")

        let descriptor = FetchDescriptor<UserProfileLocalDTO>()
        let profiles = try modelContext.fetch(descriptor)

        logger.debug("✅ Fetched \(profiles.count) profiles from SwiftData")
        return profiles
    }

    func save(_ profileDTO: UserProfileLocalDTO) async throws {
        logger.debug("💾 Saving profile to SwiftData")

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
            logger.debug("🔄 Updated existing profile")
        } else {
            modelContext.insert(profileDTO)
            logger.debug("➕ Inserted new profile")
        }

        try modelContext.save()
        logger.info("✅ Profile saved to SwiftData")
    }

    func deleteAll(_ profileDTOs: [UserProfileLocalDTO]) async throws {
        logger.debug("🗑️ Deleting \(profileDTOs.count) profiles from SwiftData")

        let descriptor = FetchDescriptor<UserProfileLocalDTO>()
        let existingProfiles = try modelContext.fetch(descriptor)

        for profileDTO in profileDTOs {
            if let existing = existingProfiles.first(where: { $0.userId == profileDTO.userId }) {
                modelContext.delete(existing)
            }
        }
        try modelContext.save()

        logger.info("✅ Profiles deleted from SwiftData")
    }

    func clear() async throws {
        logger.debug("🗑️ Clearing all profiles from SwiftData")

        try modelContext.delete(model: UserProfileLocalDTO.self)
        try modelContext.save()

        logger.info("✅ All profiles cleared from SwiftData")
    }
}
