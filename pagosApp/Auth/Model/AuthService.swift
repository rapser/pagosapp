//
//  for.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

/// Generic protocol for authentication services
/// Allows swapping implementations (Supabase, Firebase, Auth0, Custom API)
protocol AuthService {
    /// Sign up a new user
    func signUp(credentials: RegistrationCredentials) async throws -> AuthSession
    
    /// Sign in with email and password
    func signIn(credentials: LoginCredentials) async throws -> AuthSession
    
    /// Sign out current user
    func signOut() async throws
    
    /// Get current session if exists
    func getCurrentSession() async throws -> AuthSession?
    
    /// Refresh expired session
    func refreshSession(refreshToken: String) async throws -> AuthSession

    /// Set session with stored tokens
    func setSession(accessToken: String, refreshToken: String) async throws -> AuthSession

    /// Send password reset email
    func sendPasswordResetEmail(email: String) async throws
    
    /// Reset password with token
    func resetPassword(token: String, newPassword: String) async throws
    
    /// Update user email
    func updateEmail(newEmail: String) async throws
    
    /// Update user password
    func updatePassword(newPassword: String) async throws
    
    /// Delete user account
    func deleteAccount() async throws
}