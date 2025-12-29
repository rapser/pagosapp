//
//  StatsFilter.swift
//  pagosApp
//
//  Domain enum for statistics time filtering
//  Clean Architecture: Domain layer models
//

import Foundation

/// Enum for statistics time period filtering
enum StatsFilter: String, CaseIterable, Identifiable, Sendable {
    case month = "Este Mes"
    case year = "Este Año"
    case all = "Todos"

    var id: Self { self }
}
