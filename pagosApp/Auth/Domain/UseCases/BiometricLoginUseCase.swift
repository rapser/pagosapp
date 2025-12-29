//
//  BiometricLoginUseCase.swift
//  pagosApp
//
//  Use case for biometric authentication (Face ID/Touch ID)
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case for authenticating user with biometrics
@MainActor
final class BiometricLoginUseCase {
    private let biometricRepository: BiometricRepositoryProtocol
    private let authRepository: AuthRepositoryProtocol

    init(
        biometricRepository: BiometricRepositoryProtocol,
        authRepository: AuthRepositoryProtocol
    ) {
        self.biometricRepository = biometricRepository
        self.authRepository = authRepository
    }

    /// Execute biometric login
    /// - Parameter reason: Reason to show to user
    /// - Returns: Result with AuthSession or AuthError
    func execute(reason: String = "Inicia sesión con biometría") async -> Result<AuthSession, AuthError> {
        // Check if biometric is available
        guard await biometricRepository.canUseBiometrics() else {
            return .failure(.unknown("Biometric authentication not available"))
        }

        // Authenticate with biometric
        let biometricResult = await biometricRepository.authenticateWithBiometric(reason: reason)

        guard case .success(let authenticated) = biometricResult, authenticated else {
            if case .failure(let error) = biometricResult {
                return .failure(error)
            }
            return .failure(.unknown("Biometric authentication failed"))
        }

        // Get current session (credentials should be stored)
        guard let session = await authRepository.getCurrentSession() else {
            return .failure(.sessionExpired)
        }

        return .success(session)
    }

    /// Check if biometric login is available
    /// - Returns: true if available
    func canUseBiometricLogin() async -> Bool {
        await biometricRepository.canUseBiometrics()
    }

    /// Get biometric type available
    /// - Returns: BiometricType
    func getBiometricType() async -> BiometricType {
        await biometricRepository.biometricType
    }
}
