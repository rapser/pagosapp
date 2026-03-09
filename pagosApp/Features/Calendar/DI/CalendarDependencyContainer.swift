//
//  CalendarDependencyContainer.swift
//  pagosApp
//
//  Dependency Injection Container for Calendar module
//  Clean Architecture - DI Layer
//

import Foundation

/// Dependency Injection container for Calendar feature
@MainActor
final class CalendarDependencyContainer {
    private let paymentDependencyContainer: PaymentDependencyContainer
    private let reminderDependencyContainer: ReminderDependencyContainer
    private let calendarEventDataSource: CalendarEventDataSource

    // MARK: - Initialization

    init(
        paymentDependencyContainer: PaymentDependencyContainer,
        reminderDependencyContainer: ReminderDependencyContainer,
        calendarEventDataSource: CalendarEventDataSource
    ) {
        self.paymentDependencyContainer = paymentDependencyContainer
        self.reminderDependencyContainer = reminderDependencyContainer
        self.calendarEventDataSource = calendarEventDataSource
    }

    // MARK: - Repository

    func makeCalendarRepository() -> CalendarRepositoryProtocol {
        return CalendarRepositoryImpl(
            paymentRepository: paymentDependencyContainer.makePaymentRepository()
        )
    }

    // MARK: - Use Cases

    func makeGetAllPaymentsForCalendarUseCase() -> GetAllPaymentsForCalendarUseCase {
        return GetAllPaymentsForCalendarUseCase(
            calendarRepository: makeCalendarRepository()
        )
    }

    func makeGetPaymentsByDateUseCase() -> GetPaymentsByDateUseCase {
        return GetPaymentsByDateUseCase(
            calendarRepository: makeCalendarRepository()
        )
    }

    func makeGetPaymentsByMonthUseCase() -> GetPaymentsByMonthUseCase {
        return GetPaymentsByMonthUseCase(
            calendarRepository: makeCalendarRepository()
        )
    }

    // MARK: - ViewModels

    func makeCalendarViewModel() -> CalendarViewModel {
        return CalendarViewModel(
            getAllPaymentsUseCase: makeGetAllPaymentsForCalendarUseCase(),
            getPaymentsByDateUseCase: makeGetPaymentsByDateUseCase(),
            getPaymentsByMonthUseCase: makeGetPaymentsByMonthUseCase(),
            getAllRemindersUseCase: reminderDependencyContainer.makeGetAllRemindersUseCase(),
            calendarEventDataSource: calendarEventDataSource,
            mapper: PaymentUIMapper()
        )
    }
}
