//
//  StatsFilter.swift
//  pagosApp
//
//  Domain enum for statistics time filtering (stable cases; UI copy via L10n).
//

import Foundation

/// Time period for statistics. Use `L10n.Statistics.periodDisplayName` for localized labels.
enum StatsFilter: CaseIterable, Identifiable, Sendable {
    case month
    case year
    case all

    var id: Self { self }

    /// Stable, non-localized label for logs and analytics.
    var logDescription: String {
        switch self {
        case .month: return "month"
        case .year: return "year"
        case .all: return "all"
        }
    }
}
