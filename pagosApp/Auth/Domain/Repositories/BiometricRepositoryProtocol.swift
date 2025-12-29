//
//  BiometricRepositoryProtocol.swift
//  pagosApp
//
//  Biometric repository contract
//  Clean Architecture - Domain Layer
//

import Foundation

/// Protocol defining biometric authentication operations
@MainActor
protocol BiometricRepositoryProtocol {
    // MARK: - Biometric Capabilities

    /// Check if biometric authentication is available on device
    var isBiometricAvailable: Bool { get async }

    /// Get the type of biometric authentication available
    var biometricType: BiometricType { get async }

    // MARK: - Biometric Operations

    /// Request biometric authentication
    /// - Parameter reason: Reason to show to user
    /// - Returns: Result with Bool (success) or AuthError
    func authenticateWithBiometric(reason: String) async -> Result<Bool, AuthError>

    /// Check if user can use biometric authentication
    /// - Returns: true if biometric is enrolled and available
    func canUseBiometrics() async -> Bool
}
