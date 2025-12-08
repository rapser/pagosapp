//
//  CurrencyPickerRow.swift
//  pagosApp
//
//  Created on 7/12/25.
//

import SwiftUI

struct CurrencyPickerRow: View {
    let isEditing: Bool
    @Binding var selectedCurrency: Currency
    
    var body: some View {
        HStack {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundColor(Color("AppPrimary"))
                .frame(width: 25)
            
            if isEditing {
                Picker("Moneda preferida", selection: $selectedCurrency) {
                    ForEach([Currency.pen, Currency.usd], id: \.self) { currency in
                        Text(currency.symbol).tag(currency)
                    }
                }
                .pickerStyle(.segmented)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Moneda preferida")
                        .font(.caption)
                        .foregroundColor(Color("AppTextSecondary"))
                    Text(selectedCurrency.displayName)
                        .foregroundColor(Color("AppTextPrimary"))
                }
            }
        }
    }
}
