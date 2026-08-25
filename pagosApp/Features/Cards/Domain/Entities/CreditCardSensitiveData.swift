//
//  CreditCardSensitiveData.swift
//  pagosApp
//
//  Domain Entity for revealed card secrets (full number + PIN)
//  Clean Architecture - Domain Layer
//
//  Only ever produced by RevealCreditCardSensitiveDataUseCase after a successful
//  biometric check. Never persisted as-is and never logged.
//

import Foundation

struct CreditCardSensitiveData: Sendable, Equatable {
    let cardNumber: String
    let pin: String
}
