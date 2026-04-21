//
//  EnsureValidSessionUseCase.swift
//  pagosApp
//
//  Use case to ensure current session is valid (fetch + refresh if needed)
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case to ensure the current remote session is valid
/// Validates session with backend and refreshes if expired
@MainActor
final class EnsureValidSessionUseCase {
    private static let logCategory = "EnsureValidSessionUseCase"

    private let authRepository: AuthSessionRepositoryProtocol
    private let refreshSessionUseCase: RefreshSessionUseCase
    private let log: DomainLogWriter

    init(
        authRepository: AuthSessionRepositoryProtocol,
        refreshSessionUseCase: RefreshSessionUseCase,
        log: DomainLogWriter
    ) {
        self.authRepository = authRepository
        self.refreshSessionUseCase = refreshSessionUseCase
        self.log = log
    }

    /// Execute: Ensure current session is valid (fetches from backend)
    /// - Throws: AuthError if session is invalid or refresh fails
    func execute() async throws {
        log.debug("🔍 Ensuring valid session with backend", category: Self.logCategory)

        // Get current session from backend
        guard let session = await authRepository.getCurrentSession() else {
            log.error("❌ No session found in backend", category: Self.logCategory)
            throw AuthError.sessionExpired
        }

        // Check if session is expired
        if session.isExpired {
            log.info("⏰ Session expired, attempting refresh", category: Self.logCategory)

            // Attempt to refresh
            let refreshResult = await refreshSessionUseCase.execute(refreshToken: session.refreshToken)

            guard case .success = refreshResult else {
                log.error("❌ Session refresh failed", category: Self.logCategory)
                throw AuthError.sessionExpired
            }

            log.info("✅ Session refreshed successfully", category: Self.logCategory)
        } else {
            log.debug("✅ Session is valid", category: Self.logCategory)
        }
    }
}
