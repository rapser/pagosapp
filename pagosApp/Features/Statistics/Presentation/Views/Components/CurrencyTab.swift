//
//  CurrencyTab.swift
//  pagosApp
//
//  Created by miguel tomairo on 1/01/26.
//


import SwiftUI
import Charts

struct CurrencyTab: View {
    let title: String
    let symbol: String
    let totalSpending: Double?
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                Text(symbol)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            if let total = totalSpending {
                Text("\(total, format: .number.precision(.fractionLength(2)))")
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(isSelected ? Color("AppPrimary").opacity(0.1) : Color.clear)
        .foregroundColor(isSelected ? Color("AppPrimary") : Color("AppTextSecondary"))
    }
}
