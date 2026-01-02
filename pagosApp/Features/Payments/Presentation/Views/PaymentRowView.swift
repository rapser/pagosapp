
import SwiftUI

struct PaymentRowView: View {
    let payment: PaymentUI
    var onToggleStatus: () -> Void

    var body: some View {
        HStack {
            // Checkbox para marcar como pagado
            Button(action: onToggleStatus) {
                Image(systemName: payment.statusIcon)
                    .foregroundColor(payment.statusColor)
                    .font(.title2)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(payment.name)
                    .fontWeight(.bold)
                    .strikethrough(payment.isPaid, color: Color("AppTextSecondary"))
                    .foregroundColor(payment.displayColor)
                Text(payment.category.rawValue)
                    .font(.caption)
                    .foregroundColor(Color("AppTextSecondary"))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(payment.formattedAmount)
                    .fontWeight(.semibold)
                    .strikethrough(payment.isPaid, color: Color("AppTextSecondary"))
                    .foregroundColor(payment.displayColor)
                Text(payment.formattedDate)
                    .font(.caption)
                    .foregroundColor(Color("AppTextSecondary"))
            }
        }
        .opacity(payment.displayOpacity)
    }
}
