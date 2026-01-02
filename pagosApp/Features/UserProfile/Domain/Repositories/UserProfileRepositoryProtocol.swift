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
    func fetchProfile(userId: UUID) async -> Result<UserProfileEntity, UserProfileError>
    func updateProfile(_ profile: UserProfileEntity) async -> Result<UserProfileEntity, UserProfileError>

    // Local operations
    func getLocalProfile() async -> Result<UserProfileEntity?, UserProfileError>
    func saveLocalProfile(_ profile: UserProfileEntity) async -> Result<Void, UserProfileError>
    func deleteLocalProfile() async -> Result<Void, UserProfileError>
}
