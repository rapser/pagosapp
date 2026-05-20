//
//  MonthlyBarChart.swift
//  pagosApp
//

import SwiftUI
import Charts

struct MonthlyBarChart: View {
    let monthlyData: [MonthlySpendingUI]
    let currency: Currency

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.Statistics.chartLast6Months)
                    .font(.title3).bold()
                    .foregroundColor(Color("AppTextPrimary"))
                Text(currency == .pen ? "Soles (S/)" : "Dólares ($)")
                    .font(.caption)
                    .foregroundColor(Color("AppTextSecondary"))
            }
            .padding(.horizontal)

            Chart(monthlyData) { data in
                BarMark(
                    x: .value("Mes", data.month, unit: .month),
                    y: .value("Total", data.totalAmount)
                )
                .foregroundStyle(Color("AppPrimary").gradient)
                .cornerRadius(6)
                .annotation(position: .top, alignment: .center) {
                    if data.totalAmount > 0 {
                        Text("\(currency.symbol)\(formatAnnotation(data.totalAmount))")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Color("AppTextSecondary"))
                    }
                }
                .accessibilityLabel(
                    "\(data.month.formatted(.dateTime.month(.wide))): \(currency.symbol) \(String(format: "%.2f", data.totalAmount))"
                )
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: monthlyData.count)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("\(currency.symbol)\(formatAxisValue(amount))")
                                .font(.caption2)
                                .foregroundColor(Color("AppTextSecondary"))
                        }
                    }
                }
            }
            .frame(height: 240)
            .padding(.horizontal)
            .accessibilityLabel("Gráfico de gastos mensuales de los últimos 6 meses en \(currency == .pen ? "Soles" : "Dólares")")
        }
    }

    private func formatAxisValue(_ value: Double) -> String {
        value >= 1_000
            ? String(format: "%.0fK", value / 1_000)
            : String(format: "%.0f", value)
    }

    private func formatAnnotation(_ value: Double) -> String {
        value >= 1_000
            ? String(format: "%.1fK", value / 1_000)
            : String(format: "%.0f", value)
    }
}
