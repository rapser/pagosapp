//
//  EnsureValidSessionUseCase.swift
//  pagosApp
//
//  Use case to ensure current session is valid (fetch + refresh if needed)
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "EnsureValidSessionUseCase")

/// Use case to ensure the current remote session is valid
/// Validates session with backend and refreshes if expired
@MainActor
final class EnsureValidSessionUseCase {
    private let authRepository: AuthRepositoryProtocol
    private let refreshSessionUseCase: RefreshSessionUseCase

    init(
        authRepository: AuthRepositoryProtocol,
        refreshSessionUseCase: RefreshSessionUseCase
    ) {
        self.authRepository = authRepository
        self.refreshSessionUseCase = refreshSessionUseCase
    }

    /// Execute: Ensure current session is valid (fetches from backend)
    /// - Throws: AuthError if session is invalid or refresh fails
    func execute() async throws {
        logger.debug("🔍 Ensuring valid session with backend")

        // Get current session from backend
        guard let session = await authRepository.getCurrentSession() else {
            logger.error("❌ No session found in backend")
            throw AuthError.sessionExpired
        }

        // Check if session is expired
        if session.isExpired {
            logger.info("⏰ Session expired, attempting refresh")

            // Attempt to refresh
            let refreshResult = await refreshSessionUseCase.execute(refreshToken: session.refreshToken)

            guard case .success = refreshResult else {
                logger.error("❌ Session refresh failed")
                throw AuthError.sessionExpired
            }

            logger.info("✅ Session refreshed successfully")
        } else {
            logger.debug("✅ Session is valid")
        }
    }
}
