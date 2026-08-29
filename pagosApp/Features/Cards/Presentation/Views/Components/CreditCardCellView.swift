import SwiftUI

/// A single grid cell shaped like a real credit card. Shows only non-sensitive
/// data: brand, bank name, expiration date, and the masked last 4 digits.
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

                HStack {
                    Text(card.bankDisplayName)
                        .font(.caption2)
                        .foregroundStyle(textColor.opacity(0.85))
                        .lineLimit(1)
                    Spacer()
                    Text(card.expirationDisplay)
                        .font(.caption2.monospaced())
                        .foregroundStyle(textColor.opacity(0.85))
                }
            }
            .padding(14)
        }
        .aspectRatio(1.586, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    /// Banks with a recognizable brand color get it instead of the generic card-brand gradient.
    private var gradientColors: [Color] {
        switch card.bank {
        case .sip:
            return [Color(red: 0.68, green: 0.87, blue: 0.96), Color(red: 0.55, green: 0.80, blue: 0.93)]
        case .io:
            return [Color.black, Color(red: 0.12, green: 0.12, blue: 0.12)]
        case .falabella:
            return [Color(red: 0.42, green: 0.70, blue: 0.25), Color(red: 0.20, green: 0.45, blue: 0.10)]
        case .interbank:
            return [Color(red: 0.0, green: 0.65, blue: 0.30), Color(red: 0.0, green: 0.42, blue: 0.18)]
        case .scotiabank:
            return [Color(red: 0.80, green: 0.10, blue: 0.12), Color(red: 0.55, green: 0.04, blue: 0.06)]
        case .ripley:
            return [Color(red: 0.75, green: 0.75, blue: 0.77), Color(red: 0.58, green: 0.58, blue: 0.60)]
        case .bcp:
            return [Color(red: 0.05, green: 0.35, blue: 0.75), Color(red: 0.02, green: 0.18, blue: 0.45)]
        case .bbva:
            return [Color(red: 0.02, green: 0.13, blue: 0.32), Color(red: 0.01, green: 0.06, blue: 0.16)]
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

    /// Light backgrounds (Sip, Ripley) need dark text for contrast; everything else stays white.
    private var textColor: Color {
        [Bank.sip, .ripley].contains(card.bank) ? Color(red: 0.05, green: 0.2, blue: 0.35) : .white
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
        CreditCardCellView(card: CreditCard(bank: .bcp, brand: .visa, last4: "1234", expirationMonth: 12, expirationYear: 2028))
        CreditCardCellView(card: CreditCard(bank: .interbank, brand: .mastercard, last4: "5678", expirationMonth: 6, expirationYear: 2027))
    }
    .padding()
}
