//
//  SaveBiometricCredentialsUseCase.swift
//  pagosApp
//
//  Use Case to save credentials for biometric login
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "SaveBiometricCredentialsUseCase")

/// Use Case to save user credentials for biometric authentication
final class SaveBiometricCredentialsUseCase {
    private let biometricCredentialsDataSource: BiometricCredentialsDataSource

    init(biometricCredentialsDataSource: BiometricCredentialsDataSource) {
        self.biometricCredentialsDataSource = biometricCredentialsDataSource
    }

    /// Execute: Save credentials for biometric login
    /// - Parameters:
    ///   - email: User email
    ///   - password: User password
    /// - Returns: Result indicating success or failure
    func execute(email: String, password: String) -> Result<Void, AuthError> {
        logger.info("💾 Saving credentials for biometric login")

        let success = biometricCredentialsDataSource.saveCredentials(email: email, password: password)

        if success {
            // Mark that user has logged in with credentials
            _ = biometricCredentialsDataSource.setHasLoggedIn(true)
            logger.info("✅ Credentials saved successfully for biometric login")
            return .success(())
        } else {
            logger.error("❌ Failed to save credentials for biometric login")
            return .failure(.unknown("Failed to save biometric credentials"))
        }
    }
}
