import SwiftUI

struct CompactDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasPayments: Bool
    let dayOfWeek: String
    let onTap: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        let dayNumber = calendar.component(.day, from: date)

        VStack(spacing: 6) {
            // Day of week (L, M, M, etc.)
            Text(dayOfWeek)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(dayOfWeekTextColor)

            // Day number with background
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("AppPrimary"))
                        .frame(width: 44, height: 44)
                } else if isToday {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("AppPrimary").opacity(0.1))
                        .frame(width: 44, height: 44)
                }

                Text("\(dayNumber)")
                    .font(.system(size: 17, weight: isToday ? .semibold : .regular))
                    .foregroundColor(textColor)
            }
            .frame(width: 50, height: 44)

            // Payment indicator dot
            Circle()
                .fill(hasPayments ? paymentDotColor : Color.clear)
                .frame(width: 5, height: 5)
        }
        .frame(width: 50)
        .onTapGesture(perform: onTap)
    }

    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return Color("AppPrimary")
        } else {
            return Color("AppTextPrimary")
        }
    }

    private var dayOfWeekTextColor: Color {
        if isSelected {
            return Color("AppPrimary")
        } else {
            return Color("AppTextSecondary")
        }
    }

    private var paymentDotColor: Color {
        if isSelected {
            // Cuando está seleccionado: amarillo en light mode, blanco en dark mode
            return Color(uiColor: UIColor { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return .white
                } else {
                    return UIColor(named: "AppWarning") ?? .systemOrange
                }
            })
        } else {
            // Cuando NO está seleccionado: siempre azul primario
            return Color("AppPrimary")
        }
    }
}
