//
//  SaveBiometricCredentialsUseCase.swift
//  pagosApp
//
//  Use Case to save credentials for biometric login
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use Case to save user credentials for biometric authentication
final class SaveBiometricCredentialsUseCase {
    private static let logCategory = "SaveBiometricCredentialsUseCase"

    private let biometricCredentialsDataSource: BiometricCredentialsDataSource
    private let log: DomainLogWriter

    init(biometricCredentialsDataSource: BiometricCredentialsDataSource, log: DomainLogWriter) {
        self.biometricCredentialsDataSource = biometricCredentialsDataSource
        self.log = log
    }

    /// Execute: Save credentials for biometric login
    /// - Parameters:
    ///   - email: User email
    ///   - password: User password
    /// - Returns: Result indicating success or failure
    func execute(email: String, password: String) -> Result<Void, AuthError> {
        log.info("💾 Saving credentials for biometric login", category: Self.logCategory)

        let success = biometricCredentialsDataSource.saveCredentials(email: email, password: password)

        if success {
            // Mark that user has logged in with credentials
            _ = biometricCredentialsDataSource.setHasLoggedIn(true)
            log.info("✅ Credentials saved successfully for biometric login", category: Self.logCategory)
            return .success(())
        } else {
            log.error("❌ Failed to save credentials for biometric login", category: Self.logCategory)
            return .failure(.unknown("Failed to save biometric credentials"))
        }
    }
}
