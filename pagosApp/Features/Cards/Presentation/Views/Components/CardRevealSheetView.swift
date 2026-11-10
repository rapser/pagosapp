import SwiftUI

/// Bottom sheet shown after a first successful Face ID/Touch ID check, revealing the
/// card's bank name and full number. CVV is never part of this view.
/// The PIN is NOT loaded with the sheet: it shows as a skeleton placeholder until the
/// user taps "Show PIN" and passes a second, independent Face ID/Touch ID check.
/// The PIN re-hides when the app leaves the foreground (so it never lands in the app
/// switcher snapshot), and the whole sheet auto-dismisses after `autoDismissDuration`
/// so sensitive data doesn't stay on screen indefinitely if the user walks away.
struct CardRevealSheetView: View {
    private static let autoDismissDuration: TimeInterval = 180

    let card: CreditCard
    let cardNumber: String
    let pin: String?
    let isRevealingPin: Bool
    let onRevealPin: () -> Void
    let onHidePin: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
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
                pinRow
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
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                onHidePin()
            }
        }
    }

    // MARK: - PIN

    private var pinRow: some View {
        VStack(spacing: 10) {
            HStack {
                Text(L10n.Cards.Reveal.pinLabel)
                    .foregroundStyle(.secondary)
                Spacer()
                if let pin {
                    Text(pin)
                        .font(.body.monospaced())
                        .transition(.opacity)
                } else {
                    PinSkeleton()
                        .transition(.opacity)
                }
            }

            pinToggleButton
        }
        .animation(.easeInOut(duration: 0.2), value: pin)
    }

    @ViewBuilder
    private var pinToggleButton: some View {
        if pin != nil {
            Button(action: onHidePin) {
                Label(L10n.Cards.Reveal.hidePin, systemImage: "eye.slash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        } else {
            Button(action: onRevealPin) {
                HStack(spacing: 8) {
                    if isRevealingPin {
                        ProgressView()
                    } else {
                        Image(systemName: "faceid")
                    }
                    Text(L10n.Cards.Reveal.showPin)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRevealingPin)
        }
    }

    // MARK: - Helpers

    private var autoHideBanner: some View {
        let countdown = Text(
            timerInterval: revealStart...revealStart.addingTimeInterval(Self.autoDismissDuration),
            countsDown: true
        )
        .monospacedDigit()

        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(.blue)
            Text("\(L10n.Cards.Reveal.autoHideBanner) \(countdown)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var formattedNumber: String {
        cardNumber
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

/// Shimmering placeholder standing in for the PIN until it's unlocked. It never
/// contains the real value - the PIN isn't even loaded from Keychain at this point.
private struct PinSkeleton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shimmerPhase: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color.secondary.opacity(0.25))
            .frame(width: 64, height: 18)
            .overlay {
                if !reduceMotion {
                    GeometryReader { proxy in
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.45), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: proxy.size.width * 0.6)
                        .offset(x: shimmerPhase * proxy.size.width)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    shimmerPhase = 1.4
                }
            }
            .accessibilityElement()
            .accessibilityLabel(L10n.Cards.Reveal.pinLabel)
            .accessibilityValue(L10n.Cards.Reveal.showPin)
    }
}
