//
//  UserProfileError.swift
//  pagosApp
//
//  Domain errors for UserProfile feature
//  Clean Architecture: Domain errors have no UI text (use ErrorPresenter for that)
//

import Foundation

/// Domain-level errors for UserProfile operations
enum UserProfileError: Error, Equatable {
    case invalidEmail
    case invalidPhoneNumber
    case profileNotFound
    case fetchFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case saveFailed(String)
    case unauthorized
    case unknown(String)

    /// Error code for logging and debugging
    var errorCode: String {
        switch self {
        case .invalidEmail:
            return "PROFILE_INVALID_EMAIL"
        case .invalidPhoneNumber:
            return "PROFILE_INVALID_PHONE"
        case .profileNotFound:
            return "PROFILE_NOT_FOUND"
        case .fetchFailed:
            return "PROFILE_FETCH_FAILED"
        case .updateFailed:
            return "PROFILE_UPDATE_FAILED"
        case .deleteFailed:
            return "PROFILE_DELETE_FAILED"
        case .saveFailed:
            return "PROFILE_SAVE_FAILED"
        case .unauthorized:
            return "PROFILE_UNAUTHORIZED"
        case .unknown:
            return "PROFILE_UNKNOWN_ERROR"
        }
    }
}
