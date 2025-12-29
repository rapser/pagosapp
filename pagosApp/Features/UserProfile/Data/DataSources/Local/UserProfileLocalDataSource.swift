//
//  UserProfileLocalDataSource.swift
//  pagosApp
//
//  Protocol for local data source operations
//  Clean Architecture: Data layer - DataSource protocol
//

import Foundation

/// Protocol for local UserProfile operations
protocol UserProfileLocalDataSource {
    /// Fetch all profiles from local storage
    func fetchAll() async throws -> [UserProfile]

    /// Save profile to local storage
    func save(_ profile: UserProfile) async throws

    /// Delete all profiles from local storage
    func deleteAll(_ profiles: [UserProfile]) async throws

    /// Clear all local storage
    func clear() async throws
}
