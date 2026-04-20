//
//  PaymentHistoryFilter.swift
//  pagosApp
//
//  History list filter (stable cases; UI copy via L10n.History).
//

import Foundation

enum PaymentHistoryFilter: CaseIterable, Identifiable, Sendable {
    case completed
    case overdue
    case all

    var id: String { logDescription }

    /// Stable, non-localized label for logs and analytics.
    var logDescription: String {
        switch self {
        case .completed: return "completed"
        case .overdue: return "overdue"
        case .all: return "all"
        }
    }
}
