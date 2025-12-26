//
//  Currency.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

enum Currency: String, Codable, CaseIterable, Identifiable {
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
