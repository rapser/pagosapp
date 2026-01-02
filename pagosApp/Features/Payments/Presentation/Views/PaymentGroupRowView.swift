//
//  PaymentGroupRowView.swift
//  pagosApp
//
//  Row view for grouped dual-currency payments
//

import SwiftUI

/// Row view for displaying grouped payments (PEN + USD credit cards)
struct PaymentGroupRowView: View {
    let group: PaymentGroup
    var onToggleStatus: () -> Void

    var body: some View {
        HStack {
            // Checkbox para marcar como pagado
            Button(action: onToggleStatus) {
                Image(systemName: group.statusIcon)
                    .foregroundColor(group.statusColor)
                    .font(.title2)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .fontWeight(.bold)
                    .strikethrough(group.isPaid, color: Color("AppTextSecondary"))
                    .foregroundColor(group.displayColor)
                Text(group.category.rawValue)
                    .font(.caption)
                    .foregroundColor(Color("AppTextSecondary"))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                // Show both amounts: "$10.00 - S/ 1,200.00"
                Text(group.formattedAmount)
                    .fontWeight(.semibold)
                    .strikethrough(group.isPaid, color: Color("AppTextSecondary"))
                    .foregroundColor(group.displayColor)
                Text(group.formattedDate)
                    .font(.caption)
                    .foregroundColor(Color("AppTextSecondary"))
            }
        }
        .opacity(group.displayOpacity)
    }
}
