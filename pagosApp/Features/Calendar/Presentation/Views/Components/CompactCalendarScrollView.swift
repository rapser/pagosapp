import SwiftUI

struct CompactCalendarScrollView: View {
    let daysInCurrentWeek: [Date]
    let selectedDate: Date
    let hasPayments: (Date) -> Bool
    let dayOfWeekString: (Date) -> String
    let onDateTap: (Date) -> Void

    @State private var selectionToggle = false
    private let calendar = Calendar.current

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(daysInCurrentWeek, id: \.self) { date in
                        CompactDayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasPayments: hasPayments(date),
                            dayOfWeek: dayOfWeekString(date),
                            onTap: {
                                let normalized = calendar.startOfDay(for: date)
                                onDateTap(normalized)
                                selectionToggle.toggle()
                            }
                        )
                        .id(date)
                    }
                }
                .padding(.horizontal)
            }
            .onAppear {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 100_000_000)
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
