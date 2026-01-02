//
//  ValidateSessionUseCase.swift
//  pagosApp
//
//  Use case for validating current session
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case for validating if current session is valid
@MainActor
final class ValidateSessionUseCase {
    private let sessionRepository: SessionRepositoryProtocol

    init(sessionRepository: SessionRepositoryProtocol) {
        self.sessionRepository = sessionRepository
    }

    /// Execute session validation
    /// - Returns: true if session is valid and not expired
    func execute() async -> Bool {
        // Check if session exists
        guard sessionRepository.hasActiveSession else {
            return false
        }

        // Validate session with repository
        let validationResult = await sessionRepository.validateSession()

        guard case .success(let isValid) = validationResult else {
            return false
        }

        return isValid
    }

    /// Check if session is expired
    /// - Returns: true if session is expired
    func isSessionExpired() async -> Bool {
        await sessionRepository.isSessionExpired()
    }

    /// Get remaining session time
    /// - Returns: Time interval until session expires
    func sessionTimeRemaining() async -> TimeInterval {
        await sessionRepository.sessionTimeRemaining()
    }
}
