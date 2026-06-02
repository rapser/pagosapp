import SwiftUI

struct DualCurrencyAmountSection: View {
    @Binding var amountPEN: String
    @Binding var amountUSD: String
    /// When true, shows a contextual hint guiding the user to fill the missing currency
    var showAddCurrencyHint: Bool = false

    private var hasPEN: Bool { (Double(amountPEN) ?? 0) > 0 }
    private var hasUSD: Bool { (Double(amountUSD) ?? 0) > 0 }

    private var hint: String {
        if showAddCurrencyHint {
            if hasPEN && !hasUSD { return L10n.Payments.Amounts.hintAddUSD }
            if hasUSD && !hasPEN { return L10n.Payments.Amounts.hintAddPEN }
        }
        return L10n.Payments.Amounts.hintOneAmount
    }

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
                    CurrencyTextField(amount: $amountPEN)
                }

                // USD Card
                VStack(alignment: .leading, spacing: 8) {
                    Label("Dólares ($)", systemImage: "dollarsign.circle")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    CurrencyTextField(amount: $amountUSD)
                }

                Text(hint)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .animation(.default, value: hint)
            }
        }
    }
}
