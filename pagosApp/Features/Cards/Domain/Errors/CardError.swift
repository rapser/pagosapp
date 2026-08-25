//
//  CardError.swift
//  pagosApp
//
//  Domain Errors for Credit Card operations
//  Clean Architecture - Domain Layer (no UI text)
//

import Foundation

enum CardError: Error, Equatable {
    case invalidCardNumber
    case invalidPin
    case invalidExpiration
    case invalidBank
    case biometricUnavailable
    case biometricFailed
    case saveFailed(String)
    case deleteFailed(String)
    case notFound
    case unknown(String)

    var errorCode: String {
        switch self {
        case .invalidCardNumber: return "CARD_INVALID_NUMBER"
        case .invalidPin: return "CARD_INVALID_PIN"
        case .invalidExpiration: return "CARD_INVALID_EXPIRATION"
        case .invalidBank: return "CARD_INVALID_BANK"
        case .biometricUnavailable: return "CARD_BIOMETRIC_UNAVAILABLE"
        case .biometricFailed: return "CARD_BIOMETRIC_FAILED"
        case .saveFailed: return "CARD_SAVE_FAILED"
        case .deleteFailed: return "CARD_DELETE_FAILED"
        case .notFound: return "CARD_NOT_FOUND"
        case .unknown: return "CARD_UNKNOWN"
        }
    }

    static func == (lhs: CardError, rhs: CardError) -> Bool {
        lhs.errorCode == rhs.errorCode
    }
}
