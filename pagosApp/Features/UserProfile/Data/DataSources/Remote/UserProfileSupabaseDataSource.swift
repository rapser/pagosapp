//
//  UserProfileSupabaseDataSource.swift
//  pagosApp
//
//  Supabase implementation of remote data source
//  Clean Architecture: Data layer - DataSource implementation
//

import Foundation
import Supabase
import OSLog

/// Supabase implementation for UserProfile remote operations
final class UserProfileSupabaseDataSource: UserProfileRemoteDataSource {
    private let client: SupabaseClient
    private let tableName = "user_profiles"
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "UserProfileSupabaseDataSource")

    init(client: SupabaseClient) {
        self.client = client
    }

    // MARK: - Remote Operations

    func fetchProfile(userId: UUID) async throws -> UserProfileDTO? {
        logger.debug("📥 Fetching profile from Supabase for user: \(userId)")

        let profiles: [UserProfileDTO] = try await client
            .from(tableName)
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        if let profile = profiles.first {
            logger.info("✅ Profile fetched from Supabase")
            return profile
        } else {
            logger.warning("⚠️ Profile not found in Supabase")
            return nil
        }
    }

    func updateProfile(_ dto: UserProfileDTO) async throws {
        logger.debug("📤 Updating profile in Supabase for user: \(dto.userId)")

        try await client
            .from(tableName)
            .update(dto)
            .eq("user_id", value: dto.userId.uuidString)
            .execute()

        logger.info("✅ Profile updated in Supabase")
    }
}
