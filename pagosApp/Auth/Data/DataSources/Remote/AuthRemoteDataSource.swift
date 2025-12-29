//
//  AuthRemoteDataSource.swift
//  pagosApp
//
//  Protocol for remote authentication data source
//  Clean Architecture - Data Layer
//

import Foundation

/// Protocol defining remote authentication data operations
@MainActor
protocol AuthRemoteDataSource {
    // MARK: - Authentication

    /// Sign up a new user
    func signUp(email: String, password: String, metadata: [String: String]?) async throws -> SupabaseSessionDTO

    /// Sign in an existing user
    func signIn(email: String, password: String) async throws -> SupabaseSessionDTO

    /// Sign out current user
    func signOut() async throws

    /// Get current session
    func getCurrentSession() async throws -> SupabaseSessionDTO?

    /// Refresh session with refresh token
    func refreshSession(refreshToken: String) async throws -> SupabaseSessionDTO

    // MARK: - Password Management

    /// Send password reset email
    func sendPasswordResetEmail(email: String) async throws

    /// Reset password with token
    func resetPassword(token: String, newPassword: String) async throws

    /// Update user email
    func updateEmail(newEmail: String) async throws

    /// Update user password
    func updatePassword(newPassword: String) async throws

    // MARK: - Account Management

    /// Delete user account
    func deleteAccount() async throws
}
