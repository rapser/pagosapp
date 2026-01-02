//
//  CategoryPieChart.swift
//  pagosApp
//
//  Created by miguel tomairo on 1/01/26.
//


import SwiftUI
import Charts

struct CategoryPieChart: View {
    let categoryData: [CategorySpending]
    let totalSpending: Double
    let selectedCurrency: Currency
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Gastos por Categoría")
                    .font(.title3).bold()
                    .foregroundColor(Color("AppTextPrimary"))
                Spacer()
                Text("\(selectedCurrency.symbol)\(totalSpending, format: .number.precision(.fractionLength(2)))")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("AppPrimary"))
            }
            .padding(.horizontal)
            
            Chart(categoryData) { data in
                SectorMark(
                    angle: .value("Monto", data.totalAmount),
                    innerRadius: .ratio(0.618),
                    angularInset: 1.5
                )
                .cornerRadius(5)
                .foregroundStyle(by: .value("Categoría", data.category.rawValue))
            }
            .frame(height: 280)
            .chartLegend(position: .bottom, alignment: .center)
            .padding(.horizontal)

            // Lista de categorías
            VStack(spacing: 0) {
                ForEach(categoryData) { data in
                    HStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                        Text(data.category.rawValue)
                            .foregroundColor(Color("AppTextPrimary"))
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(data.currency.symbol)\(data.totalAmount, format: .number.precision(.fractionLength(2)))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("AppTextPrimary"))
                            Text("\(percentage(for: data.totalAmount, total: totalSpending))%")
                                .font(.caption2)
                                .foregroundColor(Color("AppTextSecondary"))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    if data.id != categoryData.last?.id {
                        Divider()
                            .padding(.leading, 32)
                    }
                }
            }
            .background(Color("AppBackground"))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    /// Calculate percentage safely, avoiding division by zero
    private func percentage(for amount: Double, total: Double) -> Int {
        guard total > 0 else { return 0 }
        let result = (amount / total) * 100
        guard result.isFinite else { return 0 }
        return Int(result)
    }
}
