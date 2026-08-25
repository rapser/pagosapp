import SwiftUI

/// Bottom sheet shown after a successful Face ID/Touch ID check, revealing the
/// card's bank name, full number, and PIN. CVV is never part of this view.
struct CardRevealSheetView: View {
    let card: CreditCard
    let data: CreditCardSensitiveData

    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            VStack(spacing: 4) {
                Image(systemName: "faceid")
                    .font(.title)
                    .foregroundStyle(.blue)
                Text(card.brand.displayName)
                    .font(.headline)
            }

            VStack(spacing: 16) {
                revealRow(title: L10n.Cards.Reveal.bankLabel, value: card.bankDisplayName)
                revealRow(title: L10n.Cards.Reveal.numberLabel, value: formattedNumber, monospaced: true)
                revealRow(title: L10n.Cards.Reveal.pinLabel, value: data.pin, monospaced: true)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }

    private var formattedNumber: String {
        data.cardNumber
            .enumerated()
            .map { index, char in index > 0 && index % 4 == 0 ? " \(char)" : String(char) }
            .joined()
    }

    private func revealRow(title: String, value: String, monospaced: Bool = false) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(monospaced ? .body.monospaced() : .body)
        }
    }
}
