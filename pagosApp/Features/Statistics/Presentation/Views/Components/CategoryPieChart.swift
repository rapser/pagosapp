//
//  CategoryPieChart.swift
//  pagosApp
//

import SwiftUI
import Charts

struct CategoryPieChart: View {
    let categoryData: [CategorySpendingUI]
    let totalSpending: Double
    let selectedCurrency: Currency
    let shouldShowChart: Bool

    // Paleta fija: el índice en categoryData determina el color,
    // garantizando que el slice del chart y el bullet de la leyenda sean idénticos.
    private static let palette: [Color] = [
        Color(hue: 0.60, saturation: 0.70, brightness: 0.85),  // azul
        Color(hue: 0.08, saturation: 0.85, brightness: 0.92),  // naranja
        Color(hue: 0.35, saturation: 0.65, brightness: 0.72),  // verde
        Color(hue: 0.00, saturation: 0.75, brightness: 0.82),  // rojo
        Color(hue: 0.75, saturation: 0.60, brightness: 0.80),  // púrpura
        Color(hue: 0.90, saturation: 0.65, brightness: 0.85),  // rosa
        Color(hue: 0.50, saturation: 0.70, brightness: 0.72),  // teal
        Color(hue: 0.15, saturation: 0.85, brightness: 0.88),  // amarillo
        Color(hue: 0.65, saturation: 0.70, brightness: 0.62),  // índigo
    ]

    private func color(at index: Int) -> Color {
        Self.palette[index % Self.palette.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(L10n.Statistics.chartByCategory)
                    .font(.title3).bold()
                    .foregroundColor(Color("AppTextPrimary"))
                Spacer()
                Text("\(selectedCurrency.symbol) \(totalSpending, format: .number.precision(.fractionLength(2)))")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("AppPrimary"))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .padding(.horizontal)

            if shouldShowChart {
                Chart(Array(categoryData.enumerated()), id: \.element.id) { index, data in
                    SectorMark(
                        angle: .value("Monto", data.totalAmount),
                        innerRadius: .ratio(0.618),
                        angularInset: 1.5
                    )
                    .cornerRadius(5)
                    .foregroundStyle(color(at: index))
                    .accessibilityLabel(
                        "\(L10n.Payments.categoryDisplayName(data.category)): \(data.currency.symbol) \(String(format: "%.2f", data.totalAmount))"
                    )
                }
                .frame(height: 260)
                .chartLegend(.hidden)
                .padding(.horizontal)
                .accessibilityLabel("Gráfico de gastos por categoría")
            }

            // Leyenda con colores que coinciden exactamente con los slices del chart
            VStack(spacing: 0) {
                ForEach(Array(categoryData.enumerated()), id: \.element.id) { index, data in
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(color(at: index))
                            .frame(width: 12, height: 12)

                        Text(L10n.Payments.categoryDisplayName(data.category))
                            .font(.subheadline)
                            .foregroundColor(Color("AppTextPrimary"))

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(data.currency.symbol) \(data.totalAmount, format: .number.precision(.fractionLength(2)))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("AppTextPrimary"))
                                .monospacedDigit()
                            Text("\(percentage(for: data.totalAmount, total: totalSpending))%")
                                .font(.caption2)
                                .foregroundColor(Color("AppTextSecondary"))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 9)

                    if index < categoryData.count - 1 {
                        Divider()
                            .padding(.leading, 34)
                    }
                }
            }
            .background(Color("AppBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }

    private func percentage(for amount: Double, total: Double) -> Int {
        guard total > 0 else { return 0 }
        let result = (amount / total) * 100
        guard result.isFinite else { return 0 }
        return Int(result)
    }
}
