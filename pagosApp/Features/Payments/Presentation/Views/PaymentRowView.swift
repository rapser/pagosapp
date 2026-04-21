import SwiftUI

struct PaymentRowView: View {
    let payment: PaymentUI
    var onToggleStatus: () -> Void

    var body: some View {
        HStack {
            // Checkbox para marcar como pagado
            Button(action: onToggleStatus) {
                Image(systemName: payment.statusIcon)
                    .foregroundColor(payment.statusColorToken.swiftUIColor)
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(payment.isPaid ? "Marcar como pendiente \(payment.name)" : "Marcar como pagado \(payment.name)")
            .accessibilityHint(payment.isPaid ? "Toca para cambiar a pendiente" : "Toca para marcar como pagado")

            VStack(alignment: .leading, spacing: 4) {
                Text(payment.name)
                    .fontWeight(.bold)
                    .strikethrough(payment.isPaid, color: Color("AppTextSecondary"))
                    .foregroundColor(payment.displayColorToken.swiftUIColor)
                Text(L10n.Payments.categoryDisplayName(payment.category))
                    .font(.caption)
                    .foregroundColor(Color("AppTextSecondary"))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(payment.formattedAmount)
                    .fontWeight(.semibold)
                    .strikethrough(payment.isPaid, color: Color("AppTextSecondary"))
                    .foregroundColor(payment.displayColorToken.swiftUIColor)
                Text(payment.formattedDate)
                    .font(.caption)
                    .foregroundColor(Color("AppTextSecondary"))
            }
        }
        .opacity(payment.displayOpacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(payment.name), \(payment.formattedAmount), vence \(payment.formattedDate), \(payment.isPaid ? "pagado" : "pendiente")")
        .accessibilityAddTraits(payment.isPaid ? .isSelected : [])
    }
}

extension PaymentColorToken {
    var swiftUIColor: Color {
        switch self {
        case .appSuccess:
            Color("AppSuccess")
        case .appTextSecondary:
            Color("AppTextSecondary")
        case .appTextPrimary:
            Color("AppTextPrimary")
        case .overdue:
            Color.red
        }
    }
}
