//
//  TogglePaymentStatusUseCase.swift
//  pagosApp
//
//  Use Case for toggling payment paid status
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case for toggling a payment's paid status
final class TogglePaymentStatusUseCase {
    private static let logCategory = "TogglePaymentStatusUseCase"

    private let paymentRepository: PaymentRepositoryProtocol
    private let scheduleNotificationsUseCase: SchedulePaymentNotificationsUseCase?
    private let eventBus: EventBus
    private let log: DomainLogWriter

    init(
        paymentRepository: PaymentRepositoryProtocol,
        eventBus: EventBus,
        log: DomainLogWriter,
        scheduleNotificationsUseCase: SchedulePaymentNotificationsUseCase? = nil
    ) {
        self.paymentRepository = paymentRepository
        self.eventBus = eventBus
        self.log = log
        self.scheduleNotificationsUseCase = scheduleNotificationsUseCase
    }

    /// Execute the toggle payment status use case
    /// - Parameter payment: The payment to toggle
    /// - Returns: Result with updated payment or error
    func execute(_ payment: Payment) async -> Result<Payment, PaymentError> {
        let updatedPayment = Payment(
            id: payment.id,
            name: payment.name,
            amount: payment.amount,
            currency: payment.currency,
            dueDate: payment.dueDate,
            isPaid: !payment.isPaid,
            category: payment.category,
            eventIdentifier: payment.eventIdentifier,
            syncStatus: payment.syncStatus == .synced ? .modified : payment.syncStatus,
            lastSyncedAt: payment.lastSyncedAt,
            groupId: payment.groupId
        )

        do {
            try await paymentRepository.savePayment(updatedPayment)
            if let notificationsUseCase = scheduleNotificationsUseCase {
                await MainActor.run {
                    notificationsUseCase.execute(updatedPayment)
                }
            }
            await MainActor.run {
                eventBus.publish(PaymentStatusToggledEvent(paymentId: updatedPayment.id, isPaid: updatedPayment.isPaid))
            }
            return .success(updatedPayment)
        } catch {
            log.error("Failed to toggle payment status: \(error.localizedDescription)", category: Self.logCategory)
            return .failure(.updateFailed(error.localizedDescription))
        }
    }
}
