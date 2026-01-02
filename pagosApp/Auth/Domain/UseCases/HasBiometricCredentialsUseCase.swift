//
//  HasBiometricCredentialsUseCase.swift
//  pagosApp
//
//  Use Case to check if biometric credentials are stored
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use Case to check if biometric login credentials are available
final class HasBiometricCredentialsUseCase {
    private let biometricCredentialsDataSource: BiometricCredentialsDataSource

    init(biometricCredentialsDataSource: BiometricCredentialsDataSource) {
        self.biometricCredentialsDataSource = biometricCredentialsDataSource
    }

    /// Execute: Check if biometric credentials are stored
    /// - Returns: true if credentials are available
    func execute() -> Bool {
        return biometricCredentialsDataSource.hasStoredCredentials()
    }
}
