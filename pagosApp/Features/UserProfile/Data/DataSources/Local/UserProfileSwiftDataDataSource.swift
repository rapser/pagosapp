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

    func fetchAll() async throws -> [UserProfileEntity] {
        logger.debug("📱 Fetching all profiles from SwiftData")

        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = try modelContext.fetch(descriptor)

        logger.debug("✅ Fetched \(profiles.count) profiles from SwiftData")
        return profiles.map { UserProfileMapper.toDomain(from: $0) }
    }

    func save(_ profile: UserProfileEntity) async throws {
        logger.debug("💾 Saving profile to SwiftData")

        let descriptor = FetchDescriptor<UserProfile>()
        let existingProfiles = try modelContext.fetch(descriptor)

        if let existing = existingProfiles.first(where: { $0.userId == profile.userId }) {
            existing.email = profile.email
            existing.fullName = profile.fullName
            existing.phone = profile.phone
            existing.dateOfBirth = profile.dateOfBirth
            existing.genderRawValue = profile.gender?.rawValue
            existing.country = profile.country
            existing.city = profile.city
            existing.preferredCurrencyRawValue = profile.preferredCurrency.rawValue
            logger.debug("🔄 Updated existing profile")
        } else {
            let newProfile = UserProfileMapper.toModel(from: profile)
            modelContext.insert(newProfile)
            logger.debug("➕ Inserted new profile")
        }

        try modelContext.save()
        logger.info("✅ Profile saved to SwiftData")
    }

    func deleteAll(_ profiles: [UserProfileEntity]) async throws {
        logger.debug("🗑️ Deleting \(profiles.count) profiles from SwiftData")

        let descriptor = FetchDescriptor<UserProfile>()
        let existingProfiles = try modelContext.fetch(descriptor)

        for profile in profiles {
            if let existing = existingProfiles.first(where: { $0.userId == profile.userId }) {
                modelContext.delete(existing)
            }
        }
        try modelContext.save()

        logger.info("✅ Profiles deleted from SwiftData")
    }

    func clear() async throws {
        logger.debug("🗑️ Clearing all profiles from SwiftData")

        try modelContext.delete(model: UserProfile.self)
        try modelContext.save()

        logger.info("✅ All profiles cleared from SwiftData")
    }
}
