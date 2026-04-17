//
//  CalendarViewModel.swift
//  pagosApp
//
//  ViewModel for Calendar using Clean Architecture
//  Uses Use Cases instead of direct SwiftData queries
//

import Foundation

@MainActor
@Observable
final class CalendarViewModel: BaseViewModel {
    // MARK: - Observable Properties (UI State)

    var allPayments: [PaymentUI] = []
    var paymentsForSelectedDate: [PaymentUI] = []
    var allReminders: [Reminder] = []
    var remindersForSelectedDate: [Reminder] = []
    var selectedDate: Date = Calendar.current.startOfDay(for: Date())

    // MARK: - Dependencies (Use Cases)

    private let getAllPaymentsUseCase: GetAllPaymentsForCalendarUseCase
    private let getPaymentsByDateUseCase: GetPaymentsByDateUseCase
    private let getPaymentsByMonthUseCase: GetPaymentsByMonthUseCase
    private let getAllRemindersUseCase: GetAllRemindersUseCase
    private let calendarEventDataSource: CalendarEventDataSource
    private let mapper: PaymentUIMapping

    init(
        getAllPaymentsUseCase: GetAllPaymentsForCalendarUseCase,
        getPaymentsByDateUseCase: GetPaymentsByDateUseCase,
        getPaymentsByMonthUseCase: GetPaymentsByMonthUseCase,
        getAllRemindersUseCase: GetAllRemindersUseCase,
        calendarEventDataSource: CalendarEventDataSource,
        mapper: PaymentUIMapping
    ) {
        self.getAllPaymentsUseCase = getAllPaymentsUseCase
        self.getPaymentsByDateUseCase = getPaymentsByDateUseCase
        self.getPaymentsByMonthUseCase = getPaymentsByMonthUseCase
        self.getAllRemindersUseCase = getAllRemindersUseCase
        self.calendarEventDataSource = calendarEventDataSource
        self.mapper = mapper
        super.init(category: "CalendarViewModel")
    }

    // MARK: - Data Operations

    /// Load all payments and reminders (for calendar indicators)
    func loadAllPayments() async {
        await withLoadingAndErrorHandling(
            operation: {
                async let paymentsResult = self.getAllPaymentsUseCase.execute()
                async let remindersResult = self.getAllRemindersUseCase.execute()
                
                let (paymentsRes, remindersRes) = await (paymentsResult, remindersResult)
                
                switch paymentsRes {
                case .success(let payments):
                    self.allPayments = self.mapper.toUI(payments)
                    self.logDebug("Loaded \(payments.count) payments for calendar")
                case .failure(let error):
                    self.logError(error)
                    throw error
                }
                
                switch remindersRes {
                case .success(let reminders):
                    self.allReminders = reminders
                    self.logDebug("Loaded \(reminders.count) reminders for calendar")
                case .failure:
                    self.allReminders = []
                }
                
                return (paymentsRes, remindersRes)
            },
            onError: { _ in
                self.setError(L10n.Calendar.errorLoadPayments)
            }
        )
    }

    /// Load payments and reminders for selected date
    func loadPaymentsForSelectedDate() async {
        await withLoadingAndErrorHandling(
            operation: {
                let result = await self.getPaymentsByDateUseCase.execute(for: self.selectedDate)
                
                switch result {
                case .success(let payments):
                    self.paymentsForSelectedDate = self.mapper.toUI(payments)
                    self.logDebug("Loaded \(payments.count) payments for selected date")
                    return payments
                case .failure(let error):
                    self.logError(error)
                    throw error
                }
            },
            onError: { _ in
                self.setError(L10n.Calendar.errorLoadPaymentsForDate)
            }
        )

        let calendar = Calendar.current
        remindersForSelectedDate = allReminders.filter { calendar.isDate($0.dueDate, inSameDayAs: selectedDate) }
    }

    /// Load payments for a specific month
    func loadPaymentsForMonth(_ month: Date) async {
        await withLoadingAndErrorHandling(
            operation: {
                let result = await self.getPaymentsByMonthUseCase.execute(for: month)
                
                switch result {
                case .success(let payments):
                    self.logDebug("Loaded \(payments.count) payments for month")
                    return payments
                case .failure(let error):
                    self.logError(error)
                    throw error
                }
            }
        )
    }

    /// Update selected date and reload payments
    func selectDate(_ date: Date) async {
        selectedDate = Calendar.current.startOfDay(for: date)
        await loadPaymentsForSelectedDate()
    }

    /// Check if a date has payments or reminders (for calendar indicators)
    func hasEvents(on date: Date) -> Bool {
        let cal = Calendar.current
        let hasPayment = allPayments.contains { cal.isDate($0.dueDate, inSameDayAs: date) }
        let hasReminder = allReminders.contains { cal.isDate($0.dueDate, inSameDayAs: date) }
        return hasPayment || hasReminder
    }

    /// Refresh all data
    func refresh() async {
        await loadAllPayments()
        await loadPaymentsForSelectedDate()
    }

    // MARK: - Calendar Sync Operations

    /// Sync payments with device calendar (reminders are not synced to device calendar)
    func syncPaymentsWithCalendar(completion: @escaping (SyncResult) -> Void) {
        guard !paymentsForSelectedDate.isEmpty else {
            completion(.noPayments)
            return
        }

        calendarEventDataSource.requestAccess { [weak self] granted in
            guard let self = self else { return }

            Task { @MainActor in
                if granted {
                    await self.performSync(completion: completion)
                } else {
                    completion(.accessDenied)
                }
            }
        }
    }

    private func performSync(completion: @escaping (SyncResult) -> Void) async {
        var added = 0
        var updated = 0
        var skipped = 0

        for payment in paymentsForSelectedDate where payment.dueDate >= Date() {
            let title = "Pago: \(payment.name)"

            if let eventId = payment.eventIdentifier {
                // Update existing event
                calendarEventDataSource.updateEvent(
                    eventIdentifier: eventId,
                    title: title,
                    dueDate: payment.dueDate,
                    isPaid: payment.isPaid
                )
                updated += 1
            } else {
                // Add new event
                calendarEventDataSource.addEvent(
                    title: title,
                    dueDate: payment.dueDate
                ) { eventId in
                    if eventId != nil {
                        added += 1
                    }
                }
            }
        }

        // Count skipped (past payments)
        skipped = paymentsForSelectedDate.filter { $0.dueDate < Date() }.count

        completion(.success(added: added, updated: updated, skipped: skipped))
        logDebug("Calendar sync completed: \(added) added, \(updated) updated, \(skipped) skipped")
    }

    enum SyncResult {
        case success(added: Int, updated: Int, skipped: Int)
        case noPayments
        case accessDenied
    }
}
