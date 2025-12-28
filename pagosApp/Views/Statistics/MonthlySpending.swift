//
//  MonthlySpending.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import SwiftUI

/// Estructura para almacenar los datos de gastos mensuales para el gráfico de barras.
struct MonthlySpending: Identifiable {
    let id = UUID()
    let month: Date
    let totalAmount: Double
    let currency: Currency
}
