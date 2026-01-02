//
//  LogoutUseCase.swift
//  pagosApp
//
//  Use case for user logout (preserves local data)
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case for logging out user while preserving local data
@MainActor
final class LogoutUseCase {
    private let authRepository: AuthRepositoryProtocol
    private let sessionRepository: SessionRepositoryProtocol

    init(
        authRepository: AuthRepositoryProtocol,
        sessionRepository: SessionRepositoryProtocol
    ) {
        self.authRepository = authRepository
        self.sessionRepository = sessionRepository
    }

    /// Execute logout
    /// - Returns: Result with Void or AuthError
    func execute() async -> Result<Void, AuthError> {
        // Sign out from remote
        let signOutResult = await authRepository.signOut()

        // Clear session regardless of remote signOut result
        // (offline-first: local logout should always succeed)
        await sessionRepository.clearSession()

        // End session
        await sessionRepository.endSession()

        // Notify that user logged out - SessionCoordinator will update UI state
        NotificationCenter.default.post(name: NSNotification.Name("UserDidLogout"), object: nil)

        return signOutResult
    }
}
