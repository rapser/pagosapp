//
//  ClearBiometricCredentialsUseCase.swift
//  pagosApp
//
//  Use Case to clear biometric login credentials
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "ClearBiometricCredentialsUseCase")

/// Use Case to clear stored biometric credentials
final class ClearBiometricCredentialsUseCase {
    private let biometricCredentialsDataSource: BiometricCredentialsDataSource

    init(biometricCredentialsDataSource: BiometricCredentialsDataSource) {
        self.biometricCredentialsDataSource = biometricCredentialsDataSource
    }

    /// Execute: Clear all biometric credentials and flags
    /// - Returns: Result indicating success or failure
    func execute() -> Result<Void, AuthError> {
        logger.info("🗑️ Clearing biometric credentials")

        _ = biometricCredentialsDataSource.deleteHasLoggedIn()
        let success = biometricCredentialsDataSource.deleteCredentials()

        if success {
            logger.info("✅ Biometric credentials cleared successfully")
            return .success(())
        } else {
            logger.error("❌ Failed to clear biometric credentials")
            return .failure(.unknown("Failed to clear biometric credentials"))
        }
    }
}
