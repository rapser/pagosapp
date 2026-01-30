//
//  DeletePaymentUseCase.swift
//  pagosApp
//
//  Use Case for deleting a payment
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

/// Use case for deleting a payment
final class DeletePaymentUseCase {
    private let paymentRepository: PaymentRepositoryProtocol
    private let syncCalendarUseCase: SyncPaymentWithCalendarUseCase?
    private let scheduleNotificationsUseCase: SchedulePaymentNotificationsUseCase?
    private let eventBus: EventBus
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "DeletePaymentUseCase")

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
        logger.info("🗑️ Deleting payment: \(paymentId)")

        // Get payment before deleting to check for calendar event
        var paymentToDelete: Payment?
        do {
            paymentToDelete = try await paymentRepository.getLocalPayment(id: paymentId)
        } catch {
            logger.warning("⚠️ Could not fetch payment before deletion: \(error.localizedDescription)")
        }

        do {
            try await paymentRepository.deleteLocalPayment(id: paymentId)
            logger.info("✅ Payment deleted successfully: \(paymentId)")

            // Remove calendar event if payment had one
            if let payment = paymentToDelete, let syncUseCase = syncCalendarUseCase {
                await syncUseCase.removeEvent(for: payment)
            }

            // Cancel notifications if payment had any
            if let payment = paymentToDelete, let notificationsUseCase = scheduleNotificationsUseCase {
                await MainActor.run {
                    notificationsUseCase.cancel(for: payment.id)
                }
            }

            // Publish domain event (type-safe, reactive)
            await MainActor.run {
                eventBus.publish(PaymentDeletedEvent(paymentId: paymentId))
                logger.debug("📢 Published PaymentDeletedEvent")
            }

            return .success(())
        } catch {
            logger.error("❌ Failed to delete payment: \(error.localizedDescription)")
            return .failure(.deleteFailed(error.localizedDescription))
        }
    }
}
