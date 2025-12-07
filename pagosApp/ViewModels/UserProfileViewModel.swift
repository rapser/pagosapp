//
//  UserProfileViewModel.swift
//  pagosApp
//
//  Created by miguel tomairo on 7/12/25.
//

import Foundation
import SwiftData
import Supabase
import OSLog

// DTO for profile updates
struct ProfileUpdateDTO: Encodable {
    let fullName: String
    let email: String
    let phone: String?
    let dateOfBirth: String?
    let gender: String?
    let country: String?
    let city: String?
    let preferredCurrency: String
    
    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case email
        case phone
        case dateOfBirth = "date_of_birth"
        case gender
        case country
        case city
        case preferredCurrency = "preferred_currency"
    }
}

@MainActor
final class UserProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSaving = false
    
    private let supabaseClient: SupabaseClient
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "UserProfile")
    
    init(supabaseClient: SupabaseClient, modelContext: ModelContext) {
        self.supabaseClient = supabaseClient
        self.modelContext = modelContext
    }
    
    /// Load user profile from SwiftData (local first)
    func loadLocalProfile() {
        isLoading = true
        errorMessage = nil
        
        do {
            let descriptor = FetchDescriptor<UserProfile>()
            let profiles = try modelContext.fetch(descriptor)
            
            if let localProfile = profiles.first {
                profile = localProfile
                logger.info("✅ Profile loaded from local storage")
            } else {
                logger.info("⚠️ No local profile found")
            }
            
        } catch {
            logger.error("❌ Error loading local profile: \(error.localizedDescription)")
            errorMessage = "Error al cargar el perfil local"
        }
        
        isLoading = false
    }
    
    /// Fetch user profile from Supabase and save to SwiftData
    /// Called during login
    func fetchAndSaveProfile() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get current user ID
            let userId = try await supabaseClient.auth.session.user.id
            
            logger.info("Fetching profile from Supabase for user: \(userId)")
            
            // Query user_profiles table
            let response: UserProfileDTO = try await supabaseClient
                .from("user_profiles")
                .select()
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            // Convert DTO to Model
            let profileModel = response.toModel()
            
            // Delete old profile if exists
            let descriptor = FetchDescriptor<UserProfile>()
            let existingProfiles = try modelContext.fetch(descriptor)
            existingProfiles.forEach { modelContext.delete($0) }
            
            // Save new profile to SwiftData
            modelContext.insert(profileModel)
            try modelContext.save()
            
            profile = profileModel
            logger.info("✅ Profile fetched and saved to local storage")
            
            isLoading = false
            return true
            
        } catch {
            logger.error("❌ Error fetching profile: \(error.localizedDescription)")
            errorMessage = "Error al cargar el perfil: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Update user profile in Supabase and then update SwiftData
    func updateProfile(_ updatedProfile: UserProfile) async -> Bool {
        isSaving = true
        errorMessage = nil
        
        do {
            logger.info("Updating profile for user: \(updatedProfile.userId)")
            
            // Prepare update data
            let updateData = ProfileUpdateDTO(
                fullName: updatedProfile.fullName,
                email: updatedProfile.email,
                phone: updatedProfile.phone,
                dateOfBirth: updatedProfile.dateOfBirth?.ISO8601Format(),
                gender: updatedProfile.genderRawValue,
                country: updatedProfile.country,
                city: updatedProfile.city,
                preferredCurrency: updatedProfile.preferredCurrencyRawValue
            )
            
            // Update in Supabase
            try await supabaseClient
                .from("user_profiles")
                .update(updateData)
                .eq("user_id", value: updatedProfile.userId.uuidString)
                .execute()
            
            // Update local profile
            updatedProfile.fullName = updatedProfile.fullName
            updatedProfile.email = updatedProfile.email
            updatedProfile.phone = updatedProfile.phone
            updatedProfile.dateOfBirth = updatedProfile.dateOfBirth
            updatedProfile.genderRawValue = updatedProfile.genderRawValue
            updatedProfile.country = updatedProfile.country
            updatedProfile.city = updatedProfile.city
            updatedProfile.preferredCurrencyRawValue = updatedProfile.preferredCurrencyRawValue
            
            try modelContext.save()
            
            logger.info("✅ Profile updated in Supabase and local storage")
            isSaving = false
            return true
            
        } catch {
            logger.error("❌ Error updating profile: \(error.localizedDescription)")
            errorMessage = "Error al actualizar el perfil: \(error.localizedDescription)"
            isSaving = false
            return false
        }
    }
    
    /// Clear local profile (called on logout)
    func clearLocalProfile() {
        do {
            let descriptor = FetchDescriptor<UserProfile>()
            let profiles = try modelContext.fetch(descriptor)
            profiles.forEach { modelContext.delete($0) }
            try modelContext.save()
            
            profile = nil
            logger.info("✅ Local profile cleared")
        } catch {
            logger.error("❌ Error clearing local profile: \(error.localizedDescription)")
        }
    }
}
