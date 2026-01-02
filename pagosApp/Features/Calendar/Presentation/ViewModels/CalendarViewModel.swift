//
//  CalendarViewModel.swift
//  pagosApp
//
//  ViewModel for Calendar using Clean Architecture
//  Uses Use Cases instead of direct SwiftData queries
//

import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class CalendarViewModel {
    // MARK: - Observable Properties (UI State)

    var allPayments: [PaymentUI] = []
    var paymentsForSelectedDate: [PaymentUI] = []
    var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies (Use Cases)

    private let getAllPaymentsUseCase: GetAllPaymentsForCalendarUseCase
    private let getPaymentsByDateUseCase: GetPaymentsByDateUseCase
    private let getPaymentsByMonthUseCase: GetPaymentsByMonthUseCase
    private let calendarEventDataSource: CalendarEventDataSource
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "CalendarViewModel")

    init(
        getAllPaymentsUseCase: GetAllPaymentsForCalendarUseCase,
        getPaymentsByDateUseCase: GetPaymentsByDateUseCase,
        getPaymentsByMonthUseCase: GetPaymentsByMonthUseCase,
        calendarEventDataSource: CalendarEventDataSource
    ) {
        self.getAllPaymentsUseCase = getAllPaymentsUseCase
        self.getPaymentsByDateUseCase = getPaymentsByDateUseCase
        self.getPaymentsByMonthUseCase = getPaymentsByMonthUseCase
        self.calendarEventDataSource = calendarEventDataSource
    }

    // MARK: - Data Operations

    /// Load all payments (for calendar indicators)
    func loadAllPayments() async {
        isLoading = true
        defer { isLoading = false }

        let result = await getAllPaymentsUseCase.execute()

        switch result {
        case .success(let payments):
            // Convert Domain -> UI
            allPayments = payments.toUI()
            logger.info("✅ Loaded \(payments.count) payments for calendar")

        case .failure(let error):
            logger.error("❌ Failed to load payments: \(error.errorCode)")
            errorMessage = "Error al cargar pagos"
        }
    }

    /// Load payments for selected date
    func loadPaymentsForSelectedDate() async {
        let result = await getPaymentsByDateUseCase.execute(for: selectedDate)

        switch result {
        case .success(let payments):
            // Convert Domain -> UI
            paymentsForSelectedDate = payments.toUI()
            logger.info("✅ Loaded \(payments.count) payments for selected date")

        case .failure(let error):
            logger.error("❌ Failed to load payments for date: \(error.errorCode)")
            errorMessage = "Error al cargar pagos para la fecha seleccionada"
        }
    }

    /// Load payments for a specific month
    func loadPaymentsForMonth(_ month: Date) async {
        let result = await getPaymentsByMonthUseCase.execute(for: month)

        switch result {
        case .success(let payments):
            logger.info("✅ Loaded \(payments.count) payments for month")

        case .failure(let error):
            logger.error("❌ Failed to load payments for month: \(error.errorCode)")
        }
    }

    /// Update selected date and reload payments
    func selectDate(_ date: Date) async {
        selectedDate = Calendar.current.startOfDay(for: date)
        await loadPaymentsForSelectedDate()
    }

    /// Check if a date has payments (for calendar indicators)
    func hasPayments(on date: Date) -> Bool {
        let calendar = Calendar.current
        return allPayments.contains { calendar.isDate($0.dueDate, inSameDayAs: date) }
    }

    /// Refresh all data
    func refresh() async {
        await loadAllPayments()
        await loadPaymentsForSelectedDate()
    }

    // MARK: - Calendar Sync Operations

    /// Sync payments with device calendar
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
        logger.info("✅ Calendar sync completed: \(added) added, \(updated) updated, \(skipped) skipped")
    }

    enum SyncResult {
        case success(added: Int, updated: Int, skipped: Int)
        case noPayments
        case accessDenied
    }
}
