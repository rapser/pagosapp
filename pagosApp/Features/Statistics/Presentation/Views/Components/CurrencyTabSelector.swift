//
//  CurrencyTabSelector.swift
//  pagosApp
//
//  Created by miguel tomairo on 1/01/26.
//


import SwiftUI
import Charts

struct CurrencyTabSelector: View {
    @Binding var selectedCurrency: Currency
    let totalSpending: Double
    let hasPENPayments: Bool
    let hasUSDPayments: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // Tab Soles
            Button {
                selectedCurrency = .pen
            } label: {
                CurrencyTab(
                    title: L10n.Statistics.currencySoles,
                    symbol: "S/",
                    totalSpending: selectedCurrency == .pen ? totalSpending : nil,
                    isSelected: selectedCurrency == .pen
                )
            }
            .disabled(!hasPENPayments)
            .opacity(hasPENPayments ? 1.0 : 0.5)
            .accessibilityLabel(hasPENPayments ? "Ver estadísticas en Soles" : "Sin pagos en Soles")
            .accessibilityAddTraits(selectedCurrency == .pen ? .isSelected : [])
            
            // Tab Dólares
            Button {
                selectedCurrency = .usd
            } label: {
                CurrencyTab(
                    title: L10n.Statistics.currencyDollars,
                    symbol: "$",
                    totalSpending: selectedCurrency == .usd ? totalSpending : nil,
                    isSelected: selectedCurrency == .usd
                )
            }
            .disabled(!hasUSDPayments)
            .opacity(hasUSDPayments ? 1.0 : 0.5)
            .accessibilityLabel(hasUSDPayments ? "Ver estadísticas en Dólares" : "Sin pagos en Dólares")
            .accessibilityAddTraits(selectedCurrency == .usd ? .isSelected : [])
        }
        .background(Color("AppBackground"))
        .cornerRadius(12)
        .padding(.horizontal)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("AppTextSecondary").opacity(0.2), lineWidth: 1)
                .padding(.horizontal)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Selector de moneda")
    }
}
