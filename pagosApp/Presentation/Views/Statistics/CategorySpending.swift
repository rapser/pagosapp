//
//  CategorySpending.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import SwiftUI

/// Estructura para almacenar los datos agregados para el gráfico.
struct CategorySpending: Identifiable {
    let id = UUID()
    let category: PaymentCategory
    let totalAmount: Double
    let currency: Currency
}
