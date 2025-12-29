//
//  GetAuthenticationStatusUseCase.swift
//  pagosApp
//
//  Use case to check if user is currently authenticated
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case to check current authentication status
@MainActor
final class GetAuthenticationStatusUseCase {
    private let authRepository: AuthRepositoryProtocol

    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }

    /// Execute: Check if user is authenticated
    /// - Returns: true if user has valid session
    func execute() async -> Bool {
        // Check if there's a current session
        guard let session = await authRepository.getCurrentSession() else {
            return false
        }

        // Check if session is not expired
        return !session.isExpired
    }
}
