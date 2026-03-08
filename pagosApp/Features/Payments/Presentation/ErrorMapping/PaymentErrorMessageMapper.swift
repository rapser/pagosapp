//
//  PaymentErrorMessageMapper.swift
//  pagosApp
//
//  Single source of truth for PaymentError → user-facing messages
//  Clean Architecture: Presentation layer (domain stays free of UI text)
//

import Foundation

/// Maps domain PaymentError to user-facing message strings
enum PaymentErrorMessageMapper {

    static func message(for error: PaymentError) -> String {
        switch error {
        case .invalidName:
            return L10n.PaymentError.invalidName
        case .invalidAmount:
            return L10n.PaymentError.invalidAmount
        case .invalidDate:
            return L10n.PaymentError.invalidDate
        case .saveFailed(let details):
            return L10n.PaymentError.saveFailed(details)
        case .deleteFailed(let details):
            return L10n.PaymentError.deleteFailed(details)
        case .updateFailed(let details):
            return L10n.PaymentError.updateFailed(details)
        case .notificationScheduleFailed(let details):
            return L10n.PaymentError.notificationFailed(details)
        case .calendarSyncFailed(let details):
            return L10n.PaymentError.calendarSyncFailed(details)
        case .notFound:
            return L10n.PaymentError.notFound
        case .unknown(let details):
            return L10n.PaymentError.unknown(details)
        }
    }
}
