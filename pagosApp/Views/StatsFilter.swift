//
//  StatsFilter.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import SwiftUI

/// Enum para las opciones de filtrado en la vista de estadísticas.
enum StatsFilter: String, CaseIterable, Identifiable {
    case month = "Este Mes"
    case year = "Este Año"
    case all = "Todos"
    
    var id: Self { self }
}
