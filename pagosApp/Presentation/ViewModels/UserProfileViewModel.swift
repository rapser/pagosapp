//
//  UserProfileViewModel.swift
//  pagosApp
//
//  Created by miguel tomairo on 7/12/25.
//  Modern iOS 18+ using @Observable macro
//

import Foundation
import SwiftData
import Supabase
import Observation
import OSLog

@MainActor
@Observable
final class UserProfileViewModel {
    // MARK: - Domain State
    var profile: UserProfileEntity?
    var isLoading = false
    var errorMessage: String?
    var isSaving = false

    // MARK: - UI State
    var isEditing = false
    var showSuccessAlert = false
    var showDatePicker = false
    var editableProfile: EditableProfile?

    private let repository: UserProfileRepositoryProtocol
    private let supabaseClient: SupabaseClient
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "UserProfile")

    init(repository: UserProfileRepositoryProtocol, supabaseClient: SupabaseClient) {
        self.repository = repository
        self.supabaseClient = supabaseClient
    }

    // Convenience init for production
    convenience init(supabaseClient: SupabaseClient, modelContext: ModelContext) {
        let repository = UserProfileRepository(supabaseClient: supabaseClient, modelContext: modelContext)
        self.init(repository: repository, supabaseClient: supabaseClient)
    }
    
    /// Load user profile from SwiftData (local first)
    func loadLocalProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            profile = try await repository.getLocalProfile()
            
            if profile != nil {
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
            
            // Fetch from remote
            let profileDTO = try await repository.fetchProfile(userId: userId)
            
            // Convert DTO to Domain Entity (Sendable)
            let profileEntity = UserProfileEntity(
                userId: profileDTO.userId,
                fullName: profileDTO.fullName,
                email: profileDTO.email,
                phone: profileDTO.phone,
                dateOfBirth: profileDTO.dateOfBirth,
                gender: profileDTO.gender.flatMap { UserProfileEntity.Gender(rawValue: $0) },
                country: profileDTO.country,
                city: profileDTO.city,
                preferredCurrency: Currency(rawValue: profileDTO.preferredCurrency) ?? .pen
            )
            
            // Save to local storage
            try await repository.saveProfile(profileEntity)
            
            profile = profileEntity
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
    func updateProfile(with editableProfile: EditableProfile) async -> Bool {
        guard let currentProfile = profile else {
            errorMessage = "No hay perfil cargado"
            return false
        }
        
        isSaving = true
        errorMessage = nil
        
        do {
            logger.info("Updating profile for user: \(currentProfile.userId)")
            
            // Prepare update data (excluding email which doesn't change)
            var updateData = editableProfile.toUpdateDTO()
            updateData = ProfileUpdateDTO(
                fullName: editableProfile.fullName,
                email: currentProfile.email, // Keep existing email
                phone: editableProfile.phone.isEmpty ? nil : editableProfile.phone,
                dateOfBirth: editableProfile.dateOfBirth?.ISO8601Format(),
                gender: editableProfile.gender?.rawValue,
                country: currentProfile.country, // Keep existing country
                city: editableProfile.city.isEmpty ? nil : editableProfile.city,
                preferredCurrency: editableProfile.preferredCurrency.rawValue
            )
            
            // Update in Supabase
            try await repository.updateProfile(userId: currentProfile.userId, profile: updateData)
            
            // Apply changes to create updated entity
            let updatedProfile = editableProfile.applyTo(currentProfile)
            try await repository.saveProfile(updatedProfile)
            
            // Update local state
            profile = updatedProfile
            
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
    func clearLocalProfile() async {
        do {
            try await repository.deleteLocalProfile()
            profile = nil
            logger.info("✅ Local profile cleared")
        } catch {
            logger.error("❌ Error clearing local profile: \(error.localizedDescription)")
        }
    }

    // MARK: - UI Actions

    /// Start editing mode
    func startEditing() {
        guard let profile = profile else { return }
        editableProfile = EditableProfile(from: profile)
        isEditing = true
    }

    /// Cancel editing and reset state
    func cancelEditing() {
        showDatePicker = false
        editableProfile = nil
        isEditing = false
    }

    /// Save profile changes
    func saveProfile() async {
        guard let edited = editableProfile else { return }

        let success = await updateProfile(with: edited)
        if success {
            showSuccessAlert = true
            showDatePicker = false
            editableProfile = nil
        }
    }

    // MARK: - Computed Properties

    /// Form validation
    var isFormValid: Bool {
        editableProfile?.fullName.isEmpty == false
    }

    /// Convert UserProfileEntity to UserProfile for UI components
    var profileModel: UserProfile? {
        profile?.toModel()
    }
}

