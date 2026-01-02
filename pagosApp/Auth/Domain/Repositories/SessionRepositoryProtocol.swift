//
//  SessionRepositoryProtocol.swift
//  pagosApp
//
//  Session repository contract
//  Clean Architecture - Domain Layer
//

import Foundation

/// Protocol defining session management operations
@MainActor
protocol SessionRepositoryProtocol {
    // MARK: - Session State

    /// Check if there is an active session
    var hasActiveSession: Bool { get }

    /// Get last active timestamp
    var lastActiveTimestamp: Date? { get }

    // MARK: - Session Operations

    /// Start a new session
    func startSession() async

    /// End current session
    func endSession() async

    /// Clear all session data
    func clearSession() async

    /// Update last active timestamp
    func updateLastActiveTimestamp() async

    /// Check if session is expired
    /// - Returns: true if session is expired
    func isSessionExpired() async -> Bool

    /// Get remaining session time
    /// - Returns: Time interval until session expires
    func sessionTimeRemaining() async -> TimeInterval

    /// Validate current session
    /// - Returns: Result with Bool or AuthError
    func validateSession() async -> Result<Bool, AuthError>
}
