//
//  DeletePaymentUseCase.swift
//  pagosApp
//
//  Use Case for deleting a payment
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case for deleting a payment
@MainActor
final class DeletePaymentUseCase {
    private let paymentRepository: PaymentRepositoryProtocol
    private let syncCalendarUseCase: SyncPaymentWithCalendarUseCase?
    private let scheduleNotificationsUseCase: SchedulePaymentNotificationsUseCase?
    private let eventBus: EventBus

    init(
        paymentRepository: PaymentRepositoryProtocol,
        eventBus: EventBus,
        syncCalendarUseCase: SyncPaymentWithCalendarUseCase? = nil,
        scheduleNotificationsUseCase: SchedulePaymentNotificationsUseCase? = nil
    ) {
        self.paymentRepository = paymentRepository
        self.eventBus = eventBus
        self.syncCalendarUseCase = syncCalendarUseCase
        self.scheduleNotificationsUseCase = scheduleNotificationsUseCase
    }

    /// Execute the delete payment use case
    /// - Parameter paymentId: The ID of the payment to delete
    /// - Returns: Result with success or error
    func execute(paymentId: UUID) async -> Result<Void, PaymentError> {
        var paymentToDelete: Payment?
        do {
            paymentToDelete = try await paymentRepository.getLocalPayment(id: paymentId)
        } catch {}

        do {
            try await paymentRepository.deleteLocalPayment(id: paymentId)

            if let payment = paymentToDelete, let syncUseCase = syncCalendarUseCase {
                await syncUseCase.removeEvent(for: payment)
            }
            if let payment = paymentToDelete, let notificationsUseCase = scheduleNotificationsUseCase {
                notificationsUseCase.cancel(for: payment.id)
            }
            eventBus.publish(PaymentDeletedEvent(paymentId: paymentId))

            return .success(())
        } catch {
            return .failure(.deleteFailed(error.localizedDescription))
        }
    }
}
