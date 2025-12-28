//
//  for 2.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

/// Specific protocol for UserProfile local storage
protocol UserProfileLocalStorage: LocalStorage where Entity == UserProfile {
    /// Fetch profile by user ID
    func fetchByUserId(_ userId: UUID) async throws -> UserProfile?
}