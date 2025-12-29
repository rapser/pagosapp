//
//  RefreshSessionUseCase.swift
//  pagosApp
//
//  Use case for refreshing expired session
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "RefreshSessionUseCase")

/// Use case for refreshing an expired session
@MainActor
final class RefreshSessionUseCase {
    private let authRepository: AuthRepositoryProtocol
    private let sessionRepository: SessionRepositoryProtocol

    init(
        authRepository: AuthRepositoryProtocol,
        sessionRepository: SessionRepositoryProtocol
    ) {
        self.authRepository = authRepository
        self.sessionRepository = sessionRepository
    }

    /// Execute session refresh
    /// - Parameter refreshToken: Refresh token
    /// - Returns: Result with new AuthSession or AuthError
    func execute(refreshToken: String) async -> Result<AuthSession, AuthError> {
        logger.info("🔄 Refreshing session")

        // Refresh session with auth repository
        let result = await authRepository.refreshSession(refreshToken: refreshToken)

        guard case .success(let newSession) = result else {
            logger.error("❌ Session refresh failed")
            // Clear session on failure
            await sessionRepository.clearSession()
            return result
        }

        logger.info("✅ Session refreshed successfully")

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
            logger.debug("Session still valid, no refresh needed")
            return .success(nil)
        }

        logger.info("Session expired, attempting refresh")

        // Get current session to extract refresh token
        guard let currentSession = await authRepository.getCurrentSession() else {
            return .failure(.sessionExpired)
        }

        // Refresh with stored refresh token
        let result = await execute(refreshToken: currentSession.refreshToken)

        return result.map { Optional($0) }
    }
}
