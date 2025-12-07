//
//  UserProfileService.swift
//  pagosApp
//
//  Created by miguel tomairo on 7/12/25.
//

import Foundation
import SwiftData
import Supabase
import OSLog

@MainActor
class UserProfileService {
    static let shared = UserProfileService()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "UserProfileService")
    
    private init() {}
    
    /// Fetch profile from Supabase and save to SwiftData
    /// Should be called after successful login
    func fetchAndSaveProfile(supabaseClient: SupabaseClient, modelContext: ModelContext) async -> Bool {
        // Retry logic for SwiftData initialization
        for attempt in 1...3 {
            do {
                // Get current user ID
                let userId = try await supabaseClient.auth.session.user.id
                
                logger.info("Fetching profile from Supabase for user: \(userId) (attempt \(attempt))")
                
                // Query user_profiles table
                let response: UserProfileDTO = try await supabaseClient
                    .from("user_profiles")
                    .select()
                    .eq("user_id", value: userId.uuidString)
                    .single()
                    .execute()
                    .value
                
                logger.info("✅ Profile data fetched from Supabase")
                
                // Convert DTO to Model
                let profileModel = response.toModel()
                
                // Delete old profile if exists
                let descriptor = FetchDescriptor<UserProfile>()
                let existingProfiles = try modelContext.fetch(descriptor)
                existingProfiles.forEach { modelContext.delete($0) }
                
                // Save new profile to SwiftData
                modelContext.insert(profileModel)
                try modelContext.save()
                
                logger.info("✅ Profile fetched and saved to local storage")
                return true
                
            } catch let error as DecodingError {
                logger.error("❌ Error decoding profile: \(error)")
                return false
            } catch {
                // Check if it's a SwiftData file error
                if error.localizedDescription.contains("couldn't be opened") && attempt < 3 {
                    logger.warning("⚠️ SwiftData not ready, retrying in \(attempt * 100)ms...")
                    try? await Task.sleep(nanoseconds: UInt64(attempt * 100_000_000)) // Progressive delay
                    continue
                }
                
                logger.error("❌ Error fetching profile: \(error.localizedDescription)")
                return false
            }
        }
        
        logger.error("❌ Failed to save profile after 3 attempts")
        return false
    }
    
    /// Clear local profile from SwiftData
    /// Should be called on logout
    func clearLocalProfile(modelContext: ModelContext) {
        do {
            let descriptor = FetchDescriptor<UserProfile>()
            let profiles = try modelContext.fetch(descriptor)
            profiles.forEach { modelContext.delete($0) }
            try modelContext.save()
            
            logger.info("✅ Local profile cleared")
        } catch {
            logger.error("❌ Error clearing local profile: \(error.localizedDescription)")
        }
    }
}
