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
final class UserProfileSupabaseDataSource: UserProfileRemoteDataSource, @unchecked Sendable {
    private let client: SupabaseClient
    private let tableName = "user_profiles"

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchProfile(userId: UUID) async throws -> UserProfileDTO? {
        NetworkDebugLogger.logRequest(
            "fetchProfile",
            resource: tableName,
            details: ["userId": NetworkDebugLogger.redactIdentifier(userId.uuidString)]
        )
        do {
            let profiles: [UserProfileDTO] = try await client
                .from(tableName)
                .select()
                .eq("user_id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value
            NetworkDebugLogger.logResponse("fetchProfile", resource: tableName, details: ["count": "\(profiles.count)"])
            return profiles.first
        } catch {
            NetworkDebugLogger.logFailure("fetchProfile", resource: tableName, error: error)
            throw error
        }
    }

    func updateProfile(_ dto: UserProfileDTO) async throws {
        NetworkDebugLogger.logRequest(
            "updateProfile",
            resource: tableName,
            details: ["userId": NetworkDebugLogger.redactIdentifier(dto.userId.uuidString)]
        )
        do {
            try await client
                .from(tableName)
                .update(dto)
                .eq("user_id", value: dto.userId.uuidString)
                .execute()
            NetworkDebugLogger.logResponse("updateProfile", resource: tableName)
        } catch {
            NetworkDebugLogger.logFailure("updateProfile", resource: tableName, error: error)
            throw error
        }
    }
}
