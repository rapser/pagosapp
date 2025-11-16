import SwiftUI

struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    let payments: [Payment]

    @State private var currentMonth: Date = Date()
    @State private var selectionToggle = false

    private let calendar = Calendar.current
    private let daysOfWeek = ["D", "L", "M", "M", "J", "V", "S"]

    var body: some View {
        VStack(spacing: 20) {
            // Month and Year Header
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color("AppPrimary"))
                }

                Spacer()

                Text(monthYearString)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("AppTextPrimary"))

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color("AppPrimary"))
                }
            }
            .padding(.horizontal)

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
                            hasPayments: hasPayments(on: date),
                            onTap: {
                                let normalized = calendar.startOfDay(for: date)
                                print("🎯 Tap - Original date: \(date), Normalized: \(normalized)")
                                selectedDate = normalized
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
        .padding(.vertical)
    }

    // MARK: - Helper Properties

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth).capitalized
    }

    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let _ = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        let days = calendar.generateDates(
            inside: monthInterval,
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        )

        var result: [Date?] = []

        // Add empty cells for days before the first day of the month
        let firstDayWeekday = calendar.component(.weekday, from: monthInterval.start)
        let emptyCellsCount = (firstDayWeekday - calendar.firstWeekday + 7) % 7
        result.append(contentsOf: Array(repeating: nil, count: emptyCellsCount))

        // Add actual days
        result.append(contentsOf: days)

        return result
    }

    // MARK: - Helper Methods

    private func hasPayments(on date: Date) -> Bool {
        payments.contains { calendar.isDate($0.dueDate, inSameDayAs: date) }
    }

    private func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    private func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

// MARK: - Day Cell Component

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let isToday: Bool
    let hasPayments: Bool
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

// MARK: - Calendar Extension

extension Calendar {
    func generateDates(
        inside interval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)

        enumerateDates(
            startingAfter: interval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date < interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }

        return dates
    }
}
