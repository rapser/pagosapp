//
//  ErrorSeverity.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

enum ErrorSeverity {
    case info
    case warning
    case error
    case critical

    var icon: String {
        switch self {
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "🚨"
        }
    }
}
