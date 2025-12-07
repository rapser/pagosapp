//
//  UserProfileRepository.swift
//  pagosApp
//
//  Repository using Strategy Pattern with Storage Adapters
//  Can swap between different storage implementations without breaking the app
//

import Foundation
import OSLog
import Supabase
import SwiftData

@MainActor
protocol UserProfileRepositoryProtocol {
    func fetchProfile(userId: UUID) async throws -> UserProfileDTO
    func updateProfile(userId: UUID, profile: ProfileUpdateDTO) async throws
    func getLocalProfile() async throws -> UserProfile?
    func saveProfile(_ profile: UserProfile) async throws
    func deleteLocalProfile() async throws
}

/// UserProfileRepository using Storage Adapters (Strategy Pattern)
/// Can swap remoteStorage (Supabase → Firebase → AWS) and localStorage (SwiftData → SQLite → Realm)
@MainActor
class UserProfileRepository: UserProfileRepositoryProtocol {
    private let remoteStorage: UserProfileRemoteStorage
    private let localStorage: UserProfileLocalStorage
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "UserProfileRepository")
    
    /// Primary initializer with dependency injection
    init(remoteStorage: UserProfileRemoteStorage, localStorage: UserProfileLocalStorage) {
        self.remoteStorage = remoteStorage
        self.localStorage = localStorage
        logger.info("✅ UserProfileRepository initialized with custom storage adapters")
    }
    
    /// Convenience initializer for current setup (Supabase + SwiftData)
    convenience init(supabaseClient: SupabaseClient, modelContext: ModelContext) {
        let remoteStorage = UserProfileSupabaseStorage(client: supabaseClient)
        let localStorage = UserProfileSwiftDataStorage(modelContext: modelContext)
        self.init(remoteStorage: remoteStorage, localStorage: localStorage)
    }
    
    // MARK: - Remote Operations (delegates to remoteStorage adapter)
    
    func fetchProfile(userId: UUID) async throws -> UserProfileDTO {
        logger.info("📥 Fetching profile for user: \(userId)")
        
        guard let profile = try await remoteStorage.fetchProfile(userId: userId) else {
            logger.error("❌ Profile not found for user: \(userId)")
            throw NSError(domain: "UserProfileRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Perfil no encontrado"])
        }
        
        logger.info("✅ Profile fetched successfully")
        return profile
    }
    
    func updateProfile(userId: UUID, profile: ProfileUpdateDTO) async throws {
        logger.info("📤 Updating profile for user: \(userId)")
        
        // Convert dateOfBirth string to Date if present
        let dateOfBirth: Date? = if let dateString = profile.dateOfBirth {
            ISO8601DateFormatter().date(from: dateString)
        } else {
            nil
        }
        
        // Convert to full DTO for update
        let fullDTO = UserProfileDTO(
            userId: userId,
            fullName: profile.fullName,
            email: profile.email,
            phone: profile.phone,
            dateOfBirth: dateOfBirth,
            gender: profile.gender,
            country: profile.country,
            city: profile.city,
            preferredCurrency: profile.preferredCurrency
        )
        
        try await remoteStorage.updateProfile(fullDTO)
        logger.info("✅ Profile updated successfully")
    }
    
    // MARK: - Local Operations (delegates to localStorage adapter)
    
    func getLocalProfile() async throws -> UserProfile? {
        logger.debug("📱 Fetching local profile")
        let profiles = try await localStorage.fetchAll()
        return profiles.first
    }
    
    func saveProfile(_ profile: UserProfile) async throws {
        logger.debug("💾 Saving profile locally")
        
        // Delete old profile if exists (single profile per user)
        let existingProfiles = try await localStorage.fetchAll()
        if !existingProfiles.isEmpty {
            try await localStorage.deleteAll(existingProfiles)
        }
        
        // Save new profile
        try await localStorage.save(profile)
        logger.info("✅ Profile saved to local storage")
    }
    
    func deleteLocalProfile() async throws {
        logger.info("🗑️ Deleting local profile")
        try await localStorage.clear()
        logger.info("✅ Local profile deleted")
    }
}
