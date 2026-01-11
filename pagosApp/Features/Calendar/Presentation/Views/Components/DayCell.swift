import SwiftUI

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let isToday: Bool
    let hasPayments: Bool
    let isCompact: Bool
    let onTap: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        let dayNumber = calendar.component(.day, from: date)

        return VStack(spacing: 4) {
            ZStack {
                // Background circle
                if isSelected {
                    Circle()
                        .fill(Color("AppPrimary"))
                        .frame(width: 38, height: 38)
                } else if isToday {
                    Circle()
                        .fill(Color("AppPrimary").opacity(0.1))
                        .frame(width: 38, height: 38)
                }

                Text("\(dayNumber)")
                    .font(.system(size: 16))
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(textColor)
            }
            .frame(width: 40, height: 40)

            // Payment indicator dot
            Circle()
                .fill(hasPayments ? Color("AppPrimary") : Color.clear)
                .frame(width: 4, height: 4)
        }
        .onTapGesture(perform: onTap)
    }

    private var textColor: Color {
        if isSelected {
            return .white
        } else if !isCurrentMonth {
            return Color("AppTextSecondary").opacity(0.3)
        } else if isToday {
            return Color("AppPrimary")
        } else {
            return Color("AppTextPrimary")
        }
    }
}
