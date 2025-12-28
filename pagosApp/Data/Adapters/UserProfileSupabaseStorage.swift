//
//  UserProfileSupabaseStorage.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation
import Supabase

/// Specific Supabase adapter for UserProfile
final class UserProfileSupabaseStorage: SupabaseStorageAdapter<UserProfileDTO>, UserProfileRemoteStorage {
    
    init(client: SupabaseClient) {
        super.init(client: client, tableName: "user_profiles")
    }
    
    func fetchProfile(userId: UUID) async throws -> UserProfileDTO? {
        let profiles: [UserProfileDTO] = try await client
            .from("user_profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value
        
        return profiles.first
    }
    
    func updateProfile(_ dto: UserProfileDTO) async throws {
        try await client
            .from("user_profiles")
            .update(dto)
            .eq("user_id", value: dto.userId.uuidString)
            .execute()
    }
}
