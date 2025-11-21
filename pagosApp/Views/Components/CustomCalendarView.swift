import SwiftUI

struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    let payments: [Payment]

    @State private var currentMonth: Date = Date()
    @State private var selectionToggle = false
    @State private var isExpanded = false

    private let calendar = Calendar.current
    private let daysOfWeek = ["D", "L", "M", "M", "J", "V", "S"]

    var body: some View {
        VStack(spacing: 12) {
            // Month and Year Header with expand/collapse button
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color("AppPrimary"))
                }

                Spacer()

                Button(action: { withAnimation(.spring(response: 0.3)) { isExpanded.toggle() } }) {
                    HStack(spacing: 6) {
                        Text(monthYearString)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("AppTextPrimary"))

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(Color("AppPrimary"))
                    }
                }

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color("AppPrimary"))
                }
            }
            .padding(.horizontal)

            if isExpanded {
                // Full calendar view
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
                                    hasPayments: hasPayments(on: date),
                                    isCompact: false,
                                    onTap: {
                                        let normalized = calendar.startOfDay(for: date)
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
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                // Compact horizontal scrollable calendar
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(daysInCurrentWeek, id: \.self) { date in
                                CompactDayCell(
                                    date: date,
                                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                    isToday: calendar.isDateInToday(date),
                                    hasPayments: hasPayments(on: date),
                                    dayOfWeek: dayOfWeekString(for: date),
                                    onTap: {
                                        let normalized = calendar.startOfDay(for: date)
                                        selectedDate = normalized
                                        selectionToggle.toggle()
                                    }
                                )
                                .id(date)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            proxy.scrollTo(selectedDate, anchor: .center)
                        }
                    }
                    .onChange(of: selectedDate) { oldValue, newValue in
                        withAnimation {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
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
        // weekday: 1 = Sunday, 2 = Monday, 3 = Tuesday, etc.
        // daysOfWeek array: ["D", "L", "M", "M", "J", "V", "S"] (0=D, 1=L, 2=M, etc.)
        // We need to map: 1(Sun)->0, 2(Mon)->1, 3(Tue)->2, ..., 7(Sat)->6
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

// MARK: - Day Cell Component

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

// MARK: - Compact Day Cell Component

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
