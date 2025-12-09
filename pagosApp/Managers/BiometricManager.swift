//
//  BiometricManager.swift
//  pagosApp
//
//  Handles Face ID / Touch ID authentication
//  Separated from AuthenticationManager for better Single Responsibility
//  Created by Claude Code - Fase 2 Technical Debt Reduction
//

import Foundation
import LocalAuthentication
import OSLog
import Observation

@MainActor
@Observable
final class BiometricManager {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "Biometric")
    private let context = LAContext()

    var canUseBiometrics = false
    var isLoading = false

    init() {
        checkBiometricAvailability()
    }

    // MARK: - Availability Check

    func checkBiometricAvailability() {
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        #if targetEnvironment(simulator)
        canUseBiometrics = true
        logger.info("🧪 Simulator detected: Face ID enabled for testing")
        #else
        canUseBiometrics = canEvaluate
        if let error = error {
            logger.warning("Biometrics not available: \(error.localizedDescription)")
        }
        #endif
    }

    // MARK: - Authentication

    /// Authenticate with biometrics and retrieve stored credentials
    /// - Returns: Credentials if successful, nil otherwise
    func authenticate() async -> (email: String, password: String)? {
        guard canUseBiometrics else {
            logger.warning("⚠️ Biometrics not available")
            return nil
        }

        guard KeychainManager.hasStoredCredentials() else {
            logger.warning("⚠️ No credentials stored in Keychain for Face ID")
            return nil
        }

        let context = LAContext()
        let reason = "Inicia sesión con Face ID para acceder a tus pagos."

        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
                Task { @MainActor in
                    guard let self = self else {
                        continuation.resume(returning: nil)
                        return
                    }

                    if success {
                        self.logger.info("🔐 Face ID successful")

                        guard let credentials = KeychainManager.retrieveCredentials(context: context) else {
                            self.logger.error("❌ Failed to retrieve credentials from Keychain")
                            continuation.resume(returning: nil)
                            return
                        }

                        continuation.resume(returning: credentials)
                    } else {
                        self.logger.warning("⚠️ Face ID authentication failed")
                        if let error = authenticationError {
                            self.logger.error("Face ID error: \(error.localizedDescription)")
                        }
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }

    // MARK: - Biometric Type

    var biometricType: BiometricType {
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }

    enum BiometricType {
        case faceID
        case touchID
        case opticID
        case none

        var displayName: String {
            switch self {
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            case .opticID: return "Optic ID"
            case .none: return "Biometrics"
            }
        }
    }
}
