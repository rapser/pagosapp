//
//  EmptyStateView.swift
//  pagosApp
//
//  Created by miguel tomairo on 1/01/26.
//


import SwiftUI
import Charts

struct EmptyStateView: View {
    let currency: Currency
    let filter: StatsFilter
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 50))
                .foregroundColor(Color("AppTextSecondary"))
            Text("No hay pagos en \(currency == .pen ? "Soles" : "Dólares")")
                .font(.headline)
                .foregroundColor(Color("AppTextPrimary"))
            Text("para \"\(filter.rawValue)\"")
                .font(.subheadline)
                .foregroundColor(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
