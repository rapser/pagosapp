//
//  UserProfileSwiftDataStorage.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

/// Specific SwiftData adapter for UserProfile
final class UserProfileSwiftDataStorage: SwiftDataStorageAdapter<UserProfile>, UserProfileLocalStorage {
    
    func fetchByUserId(_ userId: UUID) async throws -> UserProfile? {
        let allProfiles = try await fetchAll()
        return allProfiles.first(where: { $0.userId == userId })
    }
}
