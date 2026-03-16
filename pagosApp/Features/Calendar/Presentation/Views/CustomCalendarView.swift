import SwiftUI

struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    let payments: [PaymentUI]
    let reminders: [Reminder]

    @State private var currentMonth: Date = Date()
    @State private var isExpanded = false

    private let calendar = Calendar.current
    private let daysOfWeek = ["D", "L", "M", "M", "J", "V", "S"]

    var body: some View {
        let keys = buildEventKeys()
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
                    hasPayments: { date in
                        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
                        return keys.contains("\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)")
                    },
                    onDateTap: { date in
                        selectedDate = date
                    }
                )
            } else {
                CompactCalendarScrollView(
                    daysInCurrentWeek: daysInCurrentWeek,
                    selectedDate: selectedDate,
                    hasPayments: { date in
                        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
                        return keys.contains("\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)")
                    },
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

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    private var monthYearString: String {
        Self.monthFormatter.string(from: currentMonth).capitalized
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

    /// Builds a Set of "year-month-day" keys once per render — O(n).
    /// All 30+ cell hasEvents checks then do O(1) lookup instead of O(n) each.
    private func buildEventKeys() -> Set<String> {
        var keys = Set<String>(minimumCapacity: payments.count + reminders.count)
        for payment in payments {
            let c = calendar.dateComponents([.year, .month, .day], from: payment.dueDate)
            keys.insert("\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)")
        }
        for reminder in reminders {
            let c = calendar.dateComponents([.year, .month, .day], from: reminder.dueDate)
            keys.insert("\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)")
        }
        return keys
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
