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
                withAnimation(.spring(response: 0.3)) {
                    selectedCurrency = .pen
                }
            } label: {
                CurrencyTab(
                    title: "Soles",
                    symbol: "S/",
                    totalSpending: selectedCurrency == .pen ? totalSpending : nil,
                    isSelected: selectedCurrency == .pen
                )
            }
            .disabled(!hasPENPayments)
            .opacity(hasPENPayments ? 1.0 : 0.5)
            
            // Tab Dólares
            Button {
                withAnimation(.spring(response: 0.3)) {
                    selectedCurrency = .usd
                }
            } label: {
                CurrencyTab(
                    title: "Dólares",
                    symbol: "$",
                    totalSpending: selectedCurrency == .usd ? totalSpending : nil,
                    isSelected: selectedCurrency == .usd
                )
            }
            .disabled(!hasUSDPayments)
            .opacity(hasUSDPayments ? 1.0 : 0.5)
        }
        .background(Color("AppBackground"))
        .cornerRadius(12)
        .padding(.horizontal)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("AppTextSecondary").opacity(0.2), lineWidth: 1)
                .padding(.horizontal)
        )
    }
}
