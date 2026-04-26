//
//  UserProfileRepositoryProtocol.swift
//
//  Domain repository protocol for UserProfile
//

import Foundation

/// Protocol defining UserProfile repository operations
protocol UserProfileRepositoryProtocol: Sendable {
    nonisolated func fetchProfile(userId: UUID) async -> Result<UserProfile, UserProfileError>
    nonisolated func updateProfile(_ profile: UserProfile) async -> Result<UserProfile, UserProfileError>

    @MainActor
    func getLocalProfile() async -> Result<UserProfile?, UserProfileError>
    @MainActor
    func saveLocalProfile(_ profile: UserProfile) async -> Result<Void, UserProfileError>
    @MainActor
    func deleteLocalProfile() async -> Result<Void, UserProfileError>
}
