//
//  Currency.swift
//  pagosApp
//
//  Domain Entity for Currency
//  Clean Architecture - Domain Layer
//

import Foundation

/// Currency enum for payment amounts
enum Currency: String, Codable, CaseIterable, Identifiable, Sendable {
    case pen = "PEN" // Soles peruanos
    case usd = "USD" // Dólares americanos

    var id: String { self.rawValue }

    var symbol: String {
        switch self {
        case .pen: return "S/"
        case .usd: return "$"
        }
    }

    var displayName: String {
        switch self {
        case .pen: return "Soles (S/)"
        case .usd: return "Dólares ($)"
        }
    }
}
