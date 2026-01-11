//
//  Currency.swift
//  pagosApp
//
//  Domain Entity for Currency
//  Clean Architecture - Domain Layer
//

import Foundation

/// Currency enum for payment amounts
/// Clean Architecture: Domain enums are pure, serialization happens in Data layer
enum Currency: String, Sendable, CaseIterable {
    case pen = "PEN" // Soles peruanos
    case usd = "USD" // Dólares americanos

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
