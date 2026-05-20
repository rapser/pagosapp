//
//  CurrencyTab.swift
//  pagosApp
//

import SwiftUI

struct CurrencyTab: View {
    let title: String
    let symbol: String
    let totalSpending: Double
    let isSelected: Bool
    let isAvailable: Bool

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                Text(symbol)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        isSelected
                            ? Color("AppPrimary").opacity(0.15)
                            : Color("AppTextSecondary").opacity(0.1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            Text(totalSpending, format: .number.precision(.fractionLength(2)))
                .font(.title2)
                .fontWeight(.bold)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(isSelected ? Color("AppPrimary").opacity(0.08) : Color.clear)
        .foregroundColor(isSelected ? Color("AppPrimary") : Color("AppTextSecondary"))
        .opacity(isAvailable ? 1.0 : 0.4)
    }
}
