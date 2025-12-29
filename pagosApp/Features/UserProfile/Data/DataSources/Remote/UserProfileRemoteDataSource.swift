//
//  UserProfileRemoteDataSource.swift
//  pagosApp
//
//  Protocol for remote data source operations
//  Clean Architecture: Data layer - DataSource protocol
//

import Foundation

/// Protocol for remote UserProfile operations
protocol UserProfileRemoteDataSource {
    /// Fetch user profile from remote
    func fetchProfile(userId: UUID) async throws -> UserProfileDTO?

    /// Update user profile in remote
    func updateProfile(_ dto: UserProfileDTO) async throws
}
