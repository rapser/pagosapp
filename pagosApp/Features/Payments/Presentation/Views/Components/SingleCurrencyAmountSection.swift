import SwiftUI

struct SingleCurrencyAmountSection: View {
    @Binding var currency: Currency
    @Binding var amount: String

    var body: some View {
        Section(header: Text("Montos")) {
            Picker("Moneda", selection: $currency) {
                Text("Soles").tag(Currency.pen)
                Text("Dólares").tag(Currency.usd)
            }

            HStack {
                Text(currency.symbol)
                TextField("Monto", text: $amount)
                    .keyboardType(.decimalPad)
            }
        }
    }
}
