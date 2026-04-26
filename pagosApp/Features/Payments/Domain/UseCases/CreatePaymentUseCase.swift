//
//  CreatePaymentUseCase.swift
//  pagosApp
//
//  Use Case for creating a new payment
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case for creating a new payment with validation and side effects
@MainActor
final class CreatePaymentUseCase {
    private static let logCategory = "CreatePaymentUseCase"

    private let paymentRepository: PaymentRepositoryProtocol
    private let validator: PaymentValidator
    private let syncCalendarUseCase: SyncPaymentWithCalendarUseCase?
    private let scheduleNotificationsUseCase: SchedulePaymentNotificationsUseCase?
    private let eventBus: EventBus
    private let log: DomainLogWriter

    init(
        paymentRepository: PaymentRepositoryProtocol,
        eventBus: EventBus,
        log: DomainLogWriter,
        validator: PaymentValidator = PaymentValidator(),
        syncCalendarUseCase: SyncPaymentWithCalendarUseCase? = nil,
        scheduleNotificationsUseCase: SchedulePaymentNotificationsUseCase? = nil
    ) {
        self.paymentRepository = paymentRepository
        self.eventBus = eventBus
        self.log = log
        self.validator = validator
        self.syncCalendarUseCase = syncCalendarUseCase
        self.scheduleNotificationsUseCase = scheduleNotificationsUseCase
    }

    /// Execute the create payment use case
    /// - Parameter payment: The payment entity to create
    /// - Returns: Result with created payment or error
    func execute(_ payment: Payment) async -> Result<Payment, PaymentError> {
        do {
            try validator.validate(payment)
        } catch let error as PaymentError {
            return .failure(error)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }

        // 2. Set initial sync status
        let newPayment = payment
        // We need to ensure syncStatus is .local for new payments
        // Note: Payment is immutable, so repository will handle this

        // 3. Save to repository
        do {
            try await paymentRepository.savePayment(newPayment)

            if let syncUseCase = syncCalendarUseCase {
                let granted = await syncUseCase.requestAccess()
                if granted {
                    _ = await syncUseCase.execute(newPayment)
                }
            }

            if let notificationsUseCase = scheduleNotificationsUseCase {
                notificationsUseCase.execute(newPayment)
            }

            eventBus.publish(PaymentCreatedEvent(paymentId: newPayment.id))

            return .success(newPayment)
        } catch {
            log.error("Failed to create payment: \(error.localizedDescription)", category: Self.logCategory)
            return .failure(.saveFailed(error.localizedDescription))
        }
    }
}
