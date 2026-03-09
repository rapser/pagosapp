import SwiftUI

struct DualCurrencyAmountSection: View {
    @Binding var amountPEN: String
    @Binding var amountUSD: String

    var body: some View {
        Section(header: Text(L10n.Payments.Amounts.section)) {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.Payments.Amounts.dualCurrency)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                // PEN Card
                VStack(alignment: .leading, spacing: 8) {
                    Label("Soles (S/)", systemImage: "banknote")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("0.00", text: $amountPEN)
                        .keyboardType(.decimalPad)
                        .font(.title3)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }

                // USD Card
                VStack(alignment: .leading, spacing: 8) {
                    Label("Dólares ($)", systemImage: "dollarsign.circle")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("0.00", text: $amountUSD)
                        .keyboardType(.decimalPad)
                        .font(.title3)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }

                Text(L10n.Payments.Amounts.hintOneAmount)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
