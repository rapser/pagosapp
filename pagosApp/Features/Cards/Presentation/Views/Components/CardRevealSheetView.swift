import SwiftUI

/// Bottom sheet shown after a successful Face ID/Touch ID check, revealing the
/// card's bank name, full number, and PIN. CVV is never part of this view.
/// Both are shown in full - the Face ID check that unlocked this sheet is the
/// gate; masking them again behind an eye icon here would add no protection.
/// The sheet auto-dismisses after `autoDismissDuration` so sensitive data doesn't
/// stay on screen indefinitely if the user walks away.
struct CardRevealSheetView: View {
    private static let autoDismissDuration: TimeInterval = 180

    let card: CreditCard
    let data: CreditCardSensitiveData

    @Environment(\.dismiss) private var dismiss
    @State private var revealStart = Date()

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

            autoHideBanner
        }
        .padding()
        .task {
            do {
                try await Task.sleep(for: .seconds(Self.autoDismissDuration))
                dismiss()
            } catch {
                // Cancelled because the sheet was already dismissed manually.
            }
        }
    }

    private var autoHideBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(.blue)
            (
                Text(L10n.Cards.Reveal.autoHideBanner) + Text(" ")
                    + Text(timerInterval: revealStart...revealStart.addingTimeInterval(Self.autoDismissDuration), countsDown: true)
                        .monospacedDigit()
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
