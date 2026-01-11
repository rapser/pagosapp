//
//  PaymentError.swift
//  pagosApp
//
//  Domain Errors for Payment operations
//  Clean Architecture - Domain Layer (no UI text)
//

import Foundation

/// Domain errors for payment operations
/// Error mapping to user-friendly messages happens at Presentation layer
enum PaymentError: Error, Equatable {
    case invalidName
    case invalidAmount
    case invalidDate
    case saveFailed(String)
    case deleteFailed(String)
    case updateFailed(String)
    case notificationScheduleFailed(String)
    case calendarSyncFailed(String)
    case notFound
    case unknown(String)

    // MARK: - Error Codes for Logging

    var errorCode: String {
        switch self {
        case .invalidName:
            return "PAYMENT_INVALID_NAME"
        case .invalidAmount:
            return "PAYMENT_INVALID_AMOUNT"
        case .invalidDate:
            return "PAYMENT_INVALID_DATE"
        case .saveFailed:
            return "PAYMENT_SAVE_FAILED"
        case .deleteFailed:
            return "PAYMENT_DELETE_FAILED"
        case .updateFailed:
            return "PAYMENT_UPDATE_FAILED"
        case .notificationScheduleFailed:
            return "PAYMENT_NOTIFICATION_FAILED"
        case .calendarSyncFailed:
            return "PAYMENT_CALENDAR_FAILED"
        case .notFound:
            return "PAYMENT_NOT_FOUND"
        case .unknown:
            return "PAYMENT_UNKNOWN"
        }
    }

    // MARK: - Equatable

    static func == (lhs: PaymentError, rhs: PaymentError) -> Bool {
        lhs.errorCode == rhs.errorCode
    }
}
