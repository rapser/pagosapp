//
//  UserProfileRepositoryProtocol.swift
//  pagosApp
//
//  Domain repository protocol for UserProfile
//  Clean Architecture: Domain defines contracts, Data implements them
//

import Foundation

/// Protocol defining UserProfile repository operations
protocol UserProfileRepositoryProtocol {
    // Remote operations
    func fetchProfile(userId: UUID) async -> Result<UserProfile, UserProfileError>
    func updateProfile(_ profile: UserProfile) async -> Result<UserProfile, UserProfileError>

    // Local operations
    func getLocalProfile() async -> Result<UserProfile?, UserProfileError>
    func saveLocalProfile(_ profile: UserProfile) async -> Result<Void, UserProfileError>
    func deleteLocalProfile() async -> Result<Void, UserProfileError>
}
