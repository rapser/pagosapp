//
//  AuthRepositoryProtocol.swift
//  pagosApp
//
//  Auth repository contract
//  Clean Architecture - Domain Layer
//

import Foundation

/// Protocol defining authentication repository operations
@MainActor
protocol AuthRepositoryProtocol {
    // MARK: - Authentication Operations

    /// Sign up a new user
    /// - Parameter credentials: Registration credentials
    /// - Returns: Result with AuthSession or AuthError
    func signUp(credentials: RegistrationCredentials) async -> Result<AuthSession, AuthError>

    /// Sign in an existing user
    /// - Parameter credentials: Login credentials
    /// - Returns: Result with AuthSession or AuthError
    func signIn(credentials: LoginCredentials) async -> Result<AuthSession, AuthError>

    /// Sign out current user
    /// - Returns: Result with Void or AuthError
    func signOut() async -> Result<Void, AuthError>

    /// Get current session
    /// - Returns: Optional AuthSession
    func getCurrentSession() async -> AuthSession?

    /// Refresh expired session
    /// - Parameter refreshToken: Refresh token
    /// - Returns: Result with new AuthSession or AuthError
    func refreshSession(refreshToken: String) async -> Result<AuthSession, AuthError>

    // MARK: - Password Management

    /// Send password reset email
    /// - Parameter email: User email
    /// - Returns: Result with Void or AuthError
    func sendPasswordResetEmail(email: String) async -> Result<Void, AuthError>

    /// Reset password with token
    /// - Parameters:
    ///   - token: Reset token
    ///   - newPassword: New password
    /// - Returns: Result with Void or AuthError
    func resetPassword(token: String, newPassword: String) async -> Result<Void, AuthError>

    /// Update user email
    /// - Parameter newEmail: New email address
    /// - Returns: Result with Void or AuthError
    func updateEmail(newEmail: String) async -> Result<Void, AuthError>

    /// Update user password
    /// - Parameter newPassword: New password
    /// - Returns: Result with Void or AuthError
    func updatePassword(newPassword: String) async -> Result<Void, AuthError>

    // MARK: - Account Management

    /// Delete user account
    /// - Returns: Result with Void or AuthError
    func deleteAccount() async -> Result<Void, AuthError>

    // MARK: - User Info

    /// Get current authenticated user ID
    /// - Returns: User ID as UUID, or nil if not authenticated
    func getCurrentUserId() async -> UUID?
}
