//
//  CardBrand.swift
//  pagosApp
//
//  Domain Entity for Credit Card Brand
//  Clean Architecture - Domain Layer
//

import Foundation

/// Card network brand, auto-detected from the card number prefix (IIN ranges)
enum CardBrand: String, Sendable, CaseIterable, Codable {
    case visa
    case mastercard
    case amex
    case dinersClub
    case discover
    case unknown

    var displayName: String {
        switch self {
        case .visa: return "Visa"
        case .mastercard: return "Mastercard"
        case .amex: return "American Express"
        case .dinersClub: return "Diners Club"
        case .discover: return "Discover"
        case .unknown: return "Tarjeta"
        }
    }

    /// Detects the card brand from the card number's leading digits (IIN/BIN ranges).
    static func detect(from cardNumber: String) -> CardBrand {
        let digits = cardNumber.filter(\.isNumber)
        guard !digits.isEmpty else { return .unknown }

        if digits.hasPrefix("4") {
            return .visa
        }
        if let twoDigits = Int(digits.prefix(2)), (51...55).contains(twoDigits) {
            return .mastercard
        }
        if let fourDigits = Int(digits.prefix(4)), (2221...2720).contains(fourDigits) {
            return .mastercard
        }
        if digits.hasPrefix("34") || digits.hasPrefix("37") {
            return .amex
        }
        if digits.hasPrefix("6011") {
            return .discover
        }
        if let threeDigits = Int(digits.prefix(3)), (300...305).contains(threeDigits) {
            return .dinersClub
        }
        if digits.hasPrefix("36") || digits.hasPrefix("38") {
            return .dinersClub
        }
        return .unknown
    }
}
