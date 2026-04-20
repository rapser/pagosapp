//
//  BiometricRepositoryImpl.swift
//  pagosApp
//
//  Implementation of Biometric repository (Clean Architecture)
//  Clean Architecture - Data Layer
//

import Foundation
import LocalAuthentication

/// Implementation of BiometricRepositoryProtocol
/// Manages biometric authentication using LocalAuthentication framework
@MainActor
final class BiometricRepositoryImpl: BiometricRepositoryProtocol {
    private static let logCategory = "BiometricRepositoryImpl"

    private let context: LAContext
    private let log: DomainLogWriter

    init(context: LAContext = LAContext(), log: DomainLogWriter) {
        self.context = context
        self.log = log
    }

    // MARK: - Biometric Capabilities

    var isBiometricAvailable: Bool {
        get async {
            var error: NSError?
            let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

            #if targetEnvironment(simulator)
            return true
            #else
            if let error = error {
                log.warning("⚠️ Biometrics not available: \(error.localizedDescription)", category: Self.logCategory)
            }
            return canEvaluate
            #endif
        }
    }

    var biometricType: BiometricType {
        get async {
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
    }

    // MARK: - Biometric Operations

    func authenticateWithBiometric(reason: String) async -> Result<Bool, AuthError> {
        // Check if biometric is available
        guard await isBiometricAvailable else {
            log.warning("⚠️ Biometric authentication not available", category: Self.logCategory)
            return .failure(.unknown("Biometric authentication not available"))
        }

        // Create new context for authentication
        let authContext = LAContext()

        return await withCheckedContinuation { continuation in
            authContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                Task { @MainActor in
                    if success {
                        self.log.info("✅ Biometric authentication successful", category: Self.logCategory)
                        continuation.resume(returning: .success(true))
                    } else {
                        self.log.warning("❌ Biometric authentication failed", category: Self.logCategory)

                        if let error = error as? LAError {
                            let authError = self.mapBiometricError(error)
                            continuation.resume(returning: .failure(authError))
                        } else {
                            continuation.resume(returning: .failure(.unknown("Biometric authentication failed")))
                        }
                    }
                }
            }
        }
    }

    func canUseBiometrics() async -> Bool {
        await isBiometricAvailable
    }

    // MARK: - Error Mapping

    private func mapBiometricError(_ error: LAError) -> AuthError {
        log.error("Biometric error: \(error.localizedDescription)", category: Self.logCategory)

        switch error.code {
        case .authenticationFailed:
            return .invalidCredentials
        case .userCancel, .userFallback, .systemCancel:
            return .unknown("Authentication cancelled")
        case .biometryNotAvailable:
            return .unknown("Biometry not available")
        case .biometryNotEnrolled:
            return .unknown("Biometry not enrolled")
        case .biometryLockout:
            return .unknown("Biometry locked out")
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
