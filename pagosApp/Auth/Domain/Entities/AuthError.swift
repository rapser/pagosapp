//
//  AuthError.swift
//  pagosApp
//
//  Domain authentication errors
//  Clean Architecture - Domain Layer
//

import Foundation

/// Authentication domain errors
/// These are pure domain errors without presentation concerns
enum AuthError: Error, Equatable {
    case invalidCredentials
    case emailAlreadyExists
    case weakPassword
    case invalidEmail
    case userNotFound
    case sessionExpired
    case networkError(String)
    case unknown(String)

    /// Error code for logging and debugging
    var errorCode: String {
        switch self {
        case .invalidCredentials:
            return "AUTH_001"
        case .emailAlreadyExists:
            return "AUTH_002"
        case .weakPassword:
            return "AUTH_003"
        case .invalidEmail:
            return "AUTH_004"
        case .userNotFound:
            return "AUTH_005"
        case .sessionExpired:
            return "AUTH_006"
        case .networkError:
            return "AUTH_007"
        case .unknown:
            return "AUTH_999"
        }
    }

    // Equatable conformance
    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidCredentials, .invalidCredentials),
             (.emailAlreadyExists, .emailAlreadyExists),
             (.weakPassword, .weakPassword),
             (.invalidEmail, .invalidEmail),
             (.userNotFound, .userNotFound),
             (.sessionExpired, .sessionExpired):
            return true
        case (.networkError(let lhsMsg), .networkError(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.unknown(let lhsMsg), .unknown(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}
