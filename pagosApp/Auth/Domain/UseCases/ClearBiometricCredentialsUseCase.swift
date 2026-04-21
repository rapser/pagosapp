//
//  ClearBiometricCredentialsUseCase.swift
//  pagosApp
//
//  Use Case to clear biometric login credentials
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use Case to clear stored biometric credentials
final class ClearBiometricCredentialsUseCase {
    private static let logCategory = "ClearBiometricCredentialsUseCase"

    private let biometricCredentialsDataSource: BiometricCredentialsDataSource
    private let log: DomainLogWriter

    init(biometricCredentialsDataSource: BiometricCredentialsDataSource, log: DomainLogWriter) {
        self.biometricCredentialsDataSource = biometricCredentialsDataSource
        self.log = log
    }

    /// Execute: Clear all biometric credentials and flags
    /// - Returns: Result indicating success or failure
    func execute() -> Result<Void, AuthError> {
        log.info("\(L10n.Log.Auth.biometricClearing)", category: Self.logCategory)

        _ = biometricCredentialsDataSource.deleteHasLoggedIn()
        let success = biometricCredentialsDataSource.deleteCredentials()

        if success {
            log.info("\(L10n.Log.Auth.biometricCleared)", category: Self.logCategory)
            return .success(())
        } else {
            log.error("\(L10n.Log.Auth.biometricClearFailed)", category: Self.logCategory)
            return .failure(.unknown("Failed to clear biometric credentials"))
        }
    }
}
