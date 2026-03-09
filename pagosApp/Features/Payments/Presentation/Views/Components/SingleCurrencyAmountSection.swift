import SwiftUI

struct SingleCurrencyAmountSection: View {
    @Binding var currency: Currency
    @Binding var amount: String

    var body: some View {
        Section(header: Text(L10n.Payments.Amounts.section)) {
            Picker("Moneda", selection: $currency) {
                Text(L10n.Payments.Amounts.soles).tag(Currency.pen)
                Text(L10n.Payments.Amounts.dollars).tag(Currency.usd)
            }

            HStack {
                Text(currency.symbol)
                TextField("Monto", text: $amount)
                    .keyboardType(.decimalPad)
            }
        }
    }
}
