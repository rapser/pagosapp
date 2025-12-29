//
//  UserProfileSwiftDataDataSource.swift
//  pagosApp
//
//  SwiftData implementation of local data source
//  Clean Architecture: Data layer - DataSource implementation
//

import Foundation
import SwiftData
import OSLog

/// SwiftData implementation for UserProfile local operations
@MainActor
final class UserProfileSwiftDataDataSource: UserProfileLocalDataSource {
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "UserProfileSwiftDataDataSource")

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Local Operations

    func fetchAll() async throws -> [UserProfile] {
        logger.debug("📱 Fetching all profiles from SwiftData")

        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = try modelContext.fetch(descriptor)

        logger.debug("✅ Fetched \(profiles.count) profiles from SwiftData")
        return profiles
    }

    func save(_ profile: UserProfile) async throws {
        logger.debug("💾 Saving profile to SwiftData")

        modelContext.insert(profile)
        try modelContext.save()

        logger.info("✅ Profile saved to SwiftData")
    }

    func deleteAll(_ profiles: [UserProfile]) async throws {
        logger.debug("🗑️ Deleting \(profiles.count) profiles from SwiftData")

        for profile in profiles {
            modelContext.delete(profile)
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
