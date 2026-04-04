//
//  PaymentGroupRowView.swift
//  pagosApp
//
//  Row view for grouped dual-currency payments
//

import SwiftUI

/// Row view for displaying grouped payments (PEN + USD credit cards)
struct PaymentGroupRowView: View {
    let group: PaymentGroupUI
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
                Text(L10n.Payments.categoryDisplayName(group.category))
                    .font(.caption)
                    .foregroundColor(Color("AppTextSecondary"))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                // Show amounts vertically with compact font (PEN first, then USD)
                if let pen = group.penPayment {
                    Text("S/ \(String(format: "%.2f", pen.amount))")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .strikethrough(group.isPaid, color: Color("AppTextSecondary"))
                        .foregroundColor(group.displayColor)
                }
                if let usd = group.usdPayment {
                    Text("$ \(String(format: "%.2f", usd.amount))")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .strikethrough(group.isPaid, color: Color("AppTextSecondary"))
                        .foregroundColor(group.displayColor)
                }
                Text(group.formattedDate)
                    .font(.caption)
                    .foregroundColor(Color("AppTextSecondary"))
            }
        }
        .opacity(group.displayOpacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel({
            var label = "\(group.name), \(L10n.Payments.categoryDisplayName(group.category))"
            if let pen = group.penPayment {
                label += ", S/ \(String(format: "%.2f", pen.amount))"
            }
            if let usd = group.usdPayment {
                label += ", $ \(String(format: "%.2f", usd.amount))"
            }
            label += ", vence \(group.formattedDate), \(group.isPaid ? "pagado" : "pendiente")"
            return label
        }())
        .accessibilityAddTraits(group.isPaid ? .isSelected : [])
    }
}
