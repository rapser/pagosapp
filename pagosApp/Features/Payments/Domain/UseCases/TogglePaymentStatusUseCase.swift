//
//  TogglePaymentStatusUseCase.swift
//  pagosApp
//
//  Use Case for toggling payment paid status
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

/// Use case for toggling a payment's paid status
final class TogglePaymentStatusUseCase {
    private let paymentRepository: PaymentRepositoryProtocol
    private let scheduleNotificationsUseCase: SchedulePaymentNotificationsUseCase?
    private let eventBus: EventBus
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "TogglePaymentStatusUseCase")

    init(
        paymentRepository: PaymentRepositoryProtocol,
        eventBus: EventBus,
        scheduleNotificationsUseCase: SchedulePaymentNotificationsUseCase? = nil
    ) {
        self.paymentRepository = paymentRepository
        self.eventBus = eventBus
        self.scheduleNotificationsUseCase = scheduleNotificationsUseCase
    }

    /// Execute the toggle payment status use case
    /// - Parameter payment: The payment to toggle
    /// - Returns: Result with updated payment or error
    func execute(_ payment: Payment) async -> Result<Payment, PaymentError> {
        logger.info("🔄 Toggling payment status: \(payment.name) -> \(!payment.isPaid)")

        // Create updated payment with toggled status
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
            logger.info("✅ Payment status toggled successfully: \(payment.name)")

            // Update notifications (cancel if paid, reschedule if unpaid)
            if let notificationsUseCase = scheduleNotificationsUseCase {
                await MainActor.run {
                    notificationsUseCase.execute(updatedPayment)
                }
            }

            // Publish domain event (type-safe, reactive)
            await MainActor.run {
                eventBus.publish(PaymentStatusToggledEvent(paymentId: updatedPayment.id, isPaid: updatedPayment.isPaid))
                logger.debug("📢 Published PaymentStatusToggledEvent")
            }

            return .success(updatedPayment)
        } catch {
            logger.error("❌ Failed to toggle payment status: \(error.localizedDescription)")
            return .failure(.updateFailed(error.localizedDescription))
        }
    }
}
