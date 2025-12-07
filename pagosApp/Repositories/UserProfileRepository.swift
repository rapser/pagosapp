//
//  UserProfileRepository.swift
//  pagosApp
//
//  Created on 7/12/25.
//

import Foundation
import SwiftData
import Supabase
import OSLog

@MainActor
protocol UserProfileRepositoryProtocol {
    func fetchProfile(userId: UUID) async throws -> UserProfileDTO
    func updateProfile(userId: UUID, profile: ProfileUpdateDTO) async throws
    func getLocalProfile() async throws -> UserProfile?
    func saveProfile(_ profile: UserProfile) async throws
    func deleteLocalProfile() async throws
}

@MainActor
class UserProfileRepository: UserProfileRepositoryProtocol {
    private let supabaseClient: SupabaseClient
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "UserProfileRepository")
    
    init(supabaseClient: SupabaseClient, modelContext: ModelContext) {
        self.supabaseClient = supabaseClient
        self.modelContext = modelContext
    }
    
    // MARK: - Remote Operations
    
    func fetchProfile(userId: UUID) async throws -> UserProfileDTO {
        logger.info("Fetching profile from Supabase for user: \(userId)")
        
        let response: UserProfileDTO = try await supabaseClient
            .from("user_profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value
        
        logger.info("✅ Profile fetched from Supabase")
        return response
    }
    
    func updateProfile(userId: UUID, profile: ProfileUpdateDTO) async throws {
        logger.info("Updating profile in Supabase for user: \(userId)")
        
        try await supabaseClient
            .from("user_profiles")
            .update(profile)
            .eq("user_id", value: userId.uuidString)
            .execute()
        
        logger.info("✅ Profile updated in Supabase")
    }
    
    // MARK: - Local Operations
    
    func getLocalProfile() async throws -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = try modelContext.fetch(descriptor)
        return profiles.first
    }
    
    func saveProfile(_ profile: UserProfile) async throws {
        // Delete old profile if exists
        let descriptor = FetchDescriptor<UserProfile>()
        let existingProfiles = try modelContext.fetch(descriptor)
        existingProfiles.forEach { modelContext.delete($0) }
        
        // Insert new profile
        modelContext.insert(profile)
        try modelContext.save()
        
        logger.info("✅ Profile saved to local storage")
    }
    
    func deleteLocalProfile() async throws {
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = try modelContext.fetch(descriptor)
        profiles.forEach { modelContext.delete($0) }
        try modelContext.save()
        
        logger.info("✅ Local profile deleted")
    }
}
