//
//  UserProfileSupabaseDataSource.swift
//  pagosApp
//
//  Supabase implementation of remote data source
//  Clean Architecture: Data layer - DataSource implementation
//

import Foundation
import Supabase

/// Supabase implementation for UserProfile remote operations
final class UserProfileSupabaseDataSource: UserProfileRemoteDataSource {
    private let client: SupabaseClient
    private let tableName = "user_profiles"

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchProfile(userId: UUID) async throws -> UserProfileDTO? {
        let profiles: [UserProfileDTO] = try await client
            .from(tableName)
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value
        return profiles.first
    }

    func updateProfile(_ dto: UserProfileDTO) async throws {
        try await client
            .from(tableName)
            .update(dto)
            .eq("user_id", value: dto.userId.uuidString)
            .execute()
    }
}
