//
//  for 3.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

/// Specific protocol for UserProfile remote storage
protocol UserProfileRemoteStorage: RemoteStorage where DTO == UserProfileDTO, Identifier == UUID {
    /// Fetch profile by user ID
    func fetchProfile(userId: UUID) async throws -> UserProfileDTO?
    
    /// Update profile
    func updateProfile(_ dto: UserProfileDTO) async throws
}