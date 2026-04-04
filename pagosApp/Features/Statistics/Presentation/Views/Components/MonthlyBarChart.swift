//
//  MonthlyBarChart.swift
//  pagosApp
//
//  Created by miguel tomairo on 1/01/26.
//


import SwiftUI
import Charts

struct MonthlyBarChart: View {
    let monthlyData: [MonthlySpendingUI]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Statistics.chartLast6Months)
                .font(.title3).bold()
                .foregroundColor(Color("AppTextPrimary"))
                .padding(.horizontal)
            
            Chart(monthlyData) { data in
                BarMark(
                    x: .value("Mes", data.month, unit: .month),
                    y: .value("Total", data.totalAmount)
                )
                .foregroundStyle(Color("AppPrimary").gradient)
                .cornerRadius(6)
                .accessibilityLabel("\(data.month.formatted(.dateTime.month(.wide))): \(String(format: "%.2f", data.totalAmount))")
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: monthlyData.count)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                }
            }
            .frame(height: 220)
            .padding(.horizontal)
            .accessibilityLabel("Gráfico de gastos mensuales de los últimos 6 meses")
        }
    }
}
