//
//  RefreshSessionUseCase.swift
//  pagosApp
//
//  Use case for refreshing expired session
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case for refreshing an expired session
@MainActor
final class RefreshSessionUseCase {
    private static let logCategory = "RefreshSessionUseCase"

    private let authRepository: AuthSessionRepositoryProtocol
    private let sessionRepository: SessionRepositoryProtocol
    private let log: DomainLogWriter

    init(
        authRepository: AuthSessionRepositoryProtocol,
        sessionRepository: SessionRepositoryProtocol,
        log: DomainLogWriter
    ) {
        self.authRepository = authRepository
        self.sessionRepository = sessionRepository
        self.log = log
    }

    /// Execute session refresh
    /// - Parameter refreshToken: Refresh token
    /// - Returns: Result with new AuthSession or AuthError
    func execute(refreshToken: String) async -> Result<AuthSession, AuthError> {
        log.info("🔄 Refreshing session", category: Self.logCategory)

        // Refresh session with auth repository
        let result = await authRepository.refreshSession(refreshToken: refreshToken)

        guard case .success(let newSession) = result else {
            log.error("❌ Session refresh failed", category: Self.logCategory)
            // Clear session on failure
            await sessionRepository.clearSession()
            return result
        }

        log.info("✅ Session refreshed successfully", category: Self.logCategory)

        // Update last active timestamp
        await sessionRepository.updateLastActiveTimestamp()

        return .success(newSession)
    }

    /// Refresh session if expired
    /// - Returns: Result with new AuthSession or AuthError
    func refreshIfExpired() async -> Result<AuthSession?, AuthError> {
        // Check if session is expired
        let isExpired = await sessionRepository.isSessionExpired()

        guard isExpired else {
            log.debug("Session still valid, no refresh needed", category: Self.logCategory)
            return .success(nil)
        }

        log.info("Session expired, attempting refresh", category: Self.logCategory)

        // Get current session to extract refresh token
        guard let currentSession = await authRepository.getCurrentSession() else {
            return .failure(.sessionExpired)
        }

        // Refresh with stored refresh token
        let result = await execute(refreshToken: currentSession.refreshToken)

        return result.map { Optional($0) }
    }
}
