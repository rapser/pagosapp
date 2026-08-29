//
//  Bank.swift
//  pagosApp
//
//  Domain Entity for Bank selection
//  Clean Architecture - Domain Layer
//

import Foundation

/// Predefined bank entities for card registration. `.other` pairs with a free-text
/// name stored separately on `CreditCard.customBankName`.
enum Bank: String, Sendable, CaseIterable, Codable {
    case bcp = "BCP"
    case interbank = "Interbank"
    case bbva = "BBVA"
    case scotiabank = "Scotiabank"
    case falabella = "Falabella"
    case ripley = "Ripley"
    case sip = "Sip"
    case io = "io"
    case other = "Otro"
}
