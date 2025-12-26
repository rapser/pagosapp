
import SwiftUI
import SwiftData

struct PaymentRowView: View {
    @Bindable var payment: Payment
    var onToggleStatus: () -> Void

    var body: some View {
        HStack {
            // Checkbox para marcar como pagado
            Button(action: onToggleStatus) {
                Image(systemName: payment.isPaid ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(payment.isPaid ? Color("AppSuccess") : Color("AppTextSecondary")) // Themed colors
                    .font(.title2)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(payment.name)
                    .fontWeight(.bold)
                    .strikethrough(payment.isPaid, color: Color("AppTextSecondary")) // Themed color
                    .foregroundColor(Color("AppTextPrimary")) // Themed color
                Text(payment.category.rawValue)
                    .font(.caption)
                    .foregroundColor(Color("AppTextSecondary")) // Themed color
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(payment.currency.symbol) \(payment.amount, format: .number.precision(.fractionLength(2)))")
                    .fontWeight(.semibold)
                    .strikethrough(payment.isPaid, color: Color("AppTextSecondary")) // Themed color
                    .foregroundColor(Color("AppTextPrimary")) // Themed color
                Text(payment.dueDate, style: .date)
                    .font(.caption)
                    .foregroundColor(Color("AppTextSecondary")) // Themed color
            }
        }
    }
}
