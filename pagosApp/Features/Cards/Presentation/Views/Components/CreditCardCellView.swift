import SwiftUI

/// A single grid cell shaped like a real credit card. Shows only non-sensitive
/// data: brand, bank name, and the masked last 4 digits.
struct CreditCardCellView: View {
    let card: CreditCard

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 0) {
                Text(card.brand.displayName.uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(textColor.opacity(0.9))

                Spacer()

                Text(card.maskedNumber)
                    .font(.subheadline.monospaced().weight(.semibold))
                    .foregroundStyle(textColor)

                Text(card.bankDisplayName)
                    .font(.caption2)
                    .foregroundStyle(textColor.opacity(0.85))
                    .lineLimit(1)
            }
            .padding(14)
        }
        .aspectRatio(1.586, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    /// Sip and io get a fixed bank color instead of the brand gradient.
    private var gradientColors: [Color] {
        switch card.bank {
        case .sip:
            return [Color(red: 0.68, green: 0.87, blue: 0.96), Color(red: 0.55, green: 0.80, blue: 0.93)]
        case .io:
            return [Color.black, Color(red: 0.12, green: 0.12, blue: 0.12)]
        default:
            switch card.brand {
            case .visa: return [Color(red: 0.15, green: 0.25, blue: 0.55), Color(red: 0.05, green: 0.1, blue: 0.3)]
            case .mastercard: return [Color(red: 0.55, green: 0.15, blue: 0.15), Color(red: 0.85, green: 0.45, blue: 0.1)]
            case .amex: return [Color(red: 0.05, green: 0.35, blue: 0.45), Color(red: 0.05, green: 0.2, blue: 0.3)]
            case .dinersClub: return [Color(red: 0.3, green: 0.3, blue: 0.3), Color(red: 0.1, green: 0.1, blue: 0.1)]
            case .discover: return [Color(red: 0.75, green: 0.45, blue: 0.05), Color(red: 0.4, green: 0.2, blue: 0.02)]
            case .unknown: return [Color(red: 0.35, green: 0.35, blue: 0.4), Color(red: 0.15, green: 0.15, blue: 0.2)]
            }
        }
    }

    /// Sip's light background needs dark text for contrast; everything else stays white.
    private var textColor: Color {
        card.bank == .sip ? Color(red: 0.05, green: 0.2, blue: 0.35) : .white
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
        CreditCardCellView(card: CreditCard(bank: .bcp, brand: .visa, last4: "1234", expirationMonth: 12, expirationYear: 2028))
        CreditCardCellView(card: CreditCard(bank: .interbank, brand: .mastercard, last4: "5678", expirationMonth: 6, expirationYear: 2027))
    }
    .padding()
}
