import SwiftUI

struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    let payments: [PaymentUI]

    @State private var currentMonth: Date = Date()
    @State private var isExpanded = false

    private let calendar = Calendar.current
    private let daysOfWeek = ["D", "L", "M", "M", "J", "V", "S"]

    var body: some View {
        VStack(spacing: 12) {
            MonthYearHeaderView(
                monthYearString: monthYearString,
                isExpanded: isExpanded,
                onPreviousMonth: previousMonth,
                onNextMonth: nextMonth,
                onToggleExpand: { isExpanded.toggle() }
            )

            if isExpanded {
                FullCalendarGridView(
                    daysOfWeek: daysOfWeek,
                    daysInMonth: daysInMonth,
                    selectedDate: selectedDate,
                    currentMonth: currentMonth,
                    hasPayments: hasPayments,
                    onDateTap: { date in
                        selectedDate = date
                    }
                )
            } else {
                CompactCalendarScrollView(
                    daysInCurrentWeek: daysInCurrentWeek,
                    selectedDate: selectedDate,
                    hasPayments: hasPayments,
                    dayOfWeekString: dayOfWeekString,
                    onDateTap: { date in
                        selectedDate = date
                    }
                )
            }
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

    private var daysInCurrentWeek: [Date] {
        // Get 2 weeks before and 2 weeks after current month for smooth scrolling
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let startDate = calendar.date(byAdding: .day, value: -14, to: monthInterval.start),
              let endDate = calendar.date(byAdding: .day, value: 14, to: monthInterval.end) else {
            return []
        }

        var dates: [Date] = []
        var currentDate = startDate

        while currentDate <= endDate {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        return dates
    }

    // MARK: - Helper Methods

    private func hasPayments(on date: Date) -> Bool {
        payments.contains { calendar.isDate($0.dueDate, inSameDayAs: date) }
    }

    private func dayOfWeekString(for date: Date) -> String {
        let weekday = calendar.component(.weekday, from: date)
        return daysOfWeek[weekday - 1]
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
