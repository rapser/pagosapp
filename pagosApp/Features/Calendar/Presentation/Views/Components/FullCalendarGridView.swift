import SwiftUI

struct FullCalendarGridView: View {
    let daysOfWeek: [String]
    let daysInMonth: [Date?]
    let selectedDate: Date
    let currentMonth: Date
    let hasPayments: (Date) -> Bool
    let onDateTap: (Date) -> Void

    @State private var selectionToggle = false
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 12) {
            // Days of Week
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color("AppTextSecondary"))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 15) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                            isToday: calendar.isDateInToday(date),
                            hasPayments: hasPayments(date),
                            isCompact: false,
                            onTap: {
                                let normalized = calendar.startOfDay(for: date)
                                onDateTap(normalized)
                                selectionToggle.toggle()
                            }
                        )
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
            .id(selectionToggle)
            .padding(.horizontal)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}
