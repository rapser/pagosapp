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
        switch await authenticateWithBiometricContext(reason: reason) {
        case .success:
            return .success(true)
        case .failure(let error):
            return .failure(error)
        }
    }

    func authenticateWithBiometricContext(reason: String) async -> Result<LAContext, AuthError> {
        // Check if biometric is available
        guard await isBiometricAvailable else {
            log.warning("⚠️ Biometric authentication not available", category: Self.logCategory)
            return .failure(.unknown("Biometric authentication not available"))
        }

        // Create new context for authentication
        let authContext = LAContext()

        // The evaluatePolicy callback runs off the main actor, so it can only hand
        // back Sendable values. We resume with a plain outcome and keep the
        // non-Sendable LAContext on the main actor, returning it after the await.
        let outcome: BiometricOutcome = await withCheckedContinuation { continuation in
            authContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                if success {
                    continuation.resume(returning: .success)
                } else if let laError = error as? LAError {
                    continuation.resume(returning: .failure(code: laError.code, description: laError.localizedDescription))
                } else {
                    continuation.resume(returning: .failureUnknown)
                }
            }
        }

        switch outcome {
        case .success:
            log.info("✅ Biometric authentication successful", category: Self.logCategory)
            return .success(authContext)
        case .failure(let code, let description):
            log.warning("❌ Biometric authentication failed", category: Self.logCategory)
            return .failure(mapBiometricError(code, description: description))
        case .failureUnknown:
            log.warning("❌ Biometric authentication failed", category: Self.logCategory)
            return .failure(.unknown("Biometric authentication failed"))
        }
    }

    /// Sendable result of a biometric evaluation, safe to pass across actors.
    private enum BiometricOutcome: Sendable {
        case success
        case failure(code: LAError.Code, description: String)
        case failureUnknown
    }

    func canUseBiometrics() async -> Bool {
        await isBiometricAvailable
    }

    // MARK: - Error Mapping

    private func mapBiometricError(_ code: LAError.Code, description: String) -> AuthError {
        log.error("Biometric error: \(description)", category: Self.logCategory)

        switch code {
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
            return .unknown(description)
        }
    }
}
