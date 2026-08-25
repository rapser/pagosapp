//
//  CardErrorMessageMapper.swift
//  pagosApp
//
//  Single source of truth for CardError -> user-facing messages
//  Clean Architecture: Presentation layer (domain stays free of UI text)
//

import Foundation

enum CardErrorMessageMapper {
    static func message(for error: CardError) -> String {
        switch error {
        case .invalidCardNumber:
            return L10n.Cards.Errors.invalidCardNumber
        case .invalidPin:
            return L10n.Cards.Errors.invalidPin
        case .invalidExpiration:
            return L10n.Cards.Errors.invalidExpiration
        case .invalidBank:
            return L10n.Cards.Errors.invalidBank
        case .biometricUnavailable:
            return L10n.Cards.Errors.biometricUnavailable
        case .biometricFailed:
            return L10n.Cards.Errors.biometricFailed
        case .saveFailed:
            return L10n.Cards.Errors.saveFailed
        case .deleteFailed:
            return L10n.Cards.Errors.deleteFailed
        case .notFound:
            return L10n.Cards.Errors.notFound
        case .unknown:
            return L10n.Cards.Errors.unknown
        }
    }
}
