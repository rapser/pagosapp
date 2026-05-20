//
//  CurrencyTabSelector.swift
//  pagosApp
//

import SwiftUI

struct CurrencyTabSelector: View {
    @Binding var selectedCurrency: Currency
    let penTotal: Double
    let usdTotal: Double
    let hasPENPayments: Bool
    let hasUSDPayments: Bool

    var body: some View {
        HStack(spacing: 0) {
            Button {
                selectedCurrency = .pen
            } label: {
                CurrencyTab(
                    title: L10n.Statistics.currencySoles,
                    symbol: "S/",
                    totalSpending: penTotal,
                    isSelected: selectedCurrency == .pen,
                    isAvailable: hasPENPayments
                )
            }
            .disabled(!hasPENPayments)
            .accessibilityLabel(hasPENPayments ? "Ver estadísticas en Soles" : "Sin pagos en Soles")
            .accessibilityAddTraits(selectedCurrency == .pen ? .isSelected : [])

            Rectangle()
                .fill(Color("AppTextSecondary").opacity(0.15))
                .frame(width: 1, height: 52)

            Button {
                selectedCurrency = .usd
            } label: {
                CurrencyTab(
                    title: L10n.Statistics.currencyDollars,
                    symbol: "$",
                    totalSpending: usdTotal,
                    isSelected: selectedCurrency == .usd,
                    isAvailable: hasUSDPayments
                )
            }
            .disabled(!hasUSDPayments)
            .accessibilityLabel(hasUSDPayments ? "Ver estadísticas en Dólares" : "Sin pagos en Dólares")
            .accessibilityAddTraits(selectedCurrency == .usd ? .isSelected : [])
        }
        .background(Color("AppBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color("AppTextSecondary").opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Selector de moneda")
    }
}
