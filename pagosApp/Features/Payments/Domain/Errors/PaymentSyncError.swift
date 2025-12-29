//
//  PaymentSyncError.swift
//  pagosApp
//
//  Domain Errors for Payment Sync operations
//  Clean Architecture - Domain Layer (no UI text)
//

import Foundation

/// Domain errors for payment synchronization
enum PaymentSyncError: Error, Equatable {
    case notAuthenticated
    case sessionExpired
    case networkError
    case uploadFailed(String)
    case downloadFailed(String)
    case conflictError
    case unknown(String)

    // MARK: - Error Codes for Logging

    var errorCode: String {
        switch self {
        case .notAuthenticated:
            return "SYNC_NOT_AUTHENTICATED"
        case .sessionExpired:
            return "SYNC_SESSION_EXPIRED"
        case .networkError:
            return "SYNC_NETWORK_ERROR"
        case .uploadFailed:
            return "SYNC_UPLOAD_FAILED"
        case .downloadFailed:
            return "SYNC_DOWNLOAD_FAILED"
        case .conflictError:
            return "SYNC_CONFLICT"
        case .unknown:
            return "SYNC_UNKNOWN"
        }
    }

    // MARK: - Equatable

    static func == (lhs: PaymentSyncError, rhs: PaymentSyncError) -> Bool {
        lhs.errorCode == rhs.errorCode
    }
}
