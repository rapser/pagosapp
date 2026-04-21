//
//  UpdatePaymentUseCase.swift
//  pagosApp
//
//  Use Case for updating an existing payment
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case for updating an existing payment
final class UpdatePaymentUseCase {
    private static let logCategory = "UpdatePaymentUseCase"

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

    /// Execute the update payment use case
    /// - Parameter payment: The payment entity to update
    /// - Returns: Result with updated payment or error
    func execute(_ payment: Payment) async -> Result<Payment, PaymentError> {
        log.info("🔄 Updating payment: \(payment.name)", category: Self.logCategory)

        // 1. Validate payment
        do {
            try validator.validate(payment)
        } catch let error as PaymentError {
            log.error("❌ Validation failed: \(error.errorCode)", category: Self.logCategory)
            return .failure(error)
        } catch {
            log.error("❌ Unexpected validation error: \(error.localizedDescription)", category: Self.logCategory)
            return .failure(.unknown(error.localizedDescription))
        }

        // 2. Update sync status if needed
        let updatedPayment: Payment
        if payment.syncStatus == .synced {
            // Mark as modified when updating a synced payment
            updatedPayment = Payment(
                id: payment.id,
                name: payment.name,
                amount: payment.amount,
                currency: payment.currency,
                dueDate: payment.dueDate,
                isPaid: payment.isPaid,
                category: payment.category,
                eventIdentifier: payment.eventIdentifier,
                syncStatus: .modified,
                lastSyncedAt: payment.lastSyncedAt,
                groupId: payment.groupId
            )
        } else {
            updatedPayment = payment
        }

        // 3. Save the main payment to repository
        do {
            try await paymentRepository.savePayment(updatedPayment)
            log.info("✅ Payment updated successfully: \(payment.name)", category: Self.logCategory)
        } catch {
            log.error("❌ Failed to update payment: \(error.localizedDescription)", category: Self.logCategory)
            return .failure(.updateFailed(error.localizedDescription))
        }

        // 4. If this payment is part of a group, update the sibling payment with shared fields
        if let groupId = payment.groupId {
            log.info("🔗 Payment is part of group: \(groupId)", category: Self.logCategory)
            await updateSiblingPayment(groupId: groupId, updatedPayment: updatedPayment)
        }

        // 5. Sync with calendar (if use case is available)
        if let syncUseCase = syncCalendarUseCase {
            // Request calendar access first
            let granted = await syncUseCase.requestAccess()
            if granted {
                // Sync payment with calendar
                let syncResult = await syncUseCase.execute(updatedPayment)
                switch syncResult {
                case .success(let syncedPayment):
                    log.info("✅ Payment synced with calendar: \(syncedPayment.name)", category: Self.logCategory)
                case .failure(let error):
                    log.warning("⚠️ Failed to sync payment with calendar: \(error.errorCode)", category: Self.logCategory)
                    // Don't fail the whole operation if calendar sync fails
                }
            } else {
                log.info("ℹ️ Calendar access denied, skipping calendar sync", category: Self.logCategory)
            }
        }

        // 6. Reschedule notifications (if use case is available)
        if let notificationsUseCase = scheduleNotificationsUseCase {
            await MainActor.run {
                notificationsUseCase.execute(updatedPayment)
            }
        }

        // 7. Publish domain event (type-safe, reactive)
        await MainActor.run {
            eventBus.publish(PaymentUpdatedEvent(paymentId: updatedPayment.id))
            log.debug("📢 Published PaymentUpdatedEvent", category: Self.logCategory)
        }

        return .success(updatedPayment)
    }

    /// Update sibling payment in the same group with shared fields
    private func updateSiblingPayment(groupId: UUID, updatedPayment: Payment) async {
        do {
            // Get all local payments in the group
            let allPayments = try await paymentRepository.getAllLocalPayments()
            let groupPayments = allPayments.filter { $0.groupId == groupId && $0.id != updatedPayment.id }

            guard let siblingPayment = groupPayments.first else {
                log.debug("ℹ️ No sibling payment found in group", category: Self.logCategory)
                return
            }

            log.info("🔄 Updating sibling payment: \(siblingPayment.name)", category: Self.logCategory)

            // Update sibling with shared fields: name, dueDate, category
            // Keep sibling's own fields: amount, currency, isPaid, eventIdentifier
            let updatedSibling = Payment(
                id: siblingPayment.id,
                name: updatedPayment.name,  // Shared: same name
                amount: siblingPayment.amount,  // Keep original amount
                currency: siblingPayment.currency,  // Keep original currency
                dueDate: updatedPayment.dueDate,  // Shared: same due date
                isPaid: siblingPayment.isPaid,  // Keep original paid status
                category: updatedPayment.category,  // Shared: same category
                eventIdentifier: siblingPayment.eventIdentifier,  // Keep original event
                syncStatus: siblingPayment.syncStatus == SyncStatus.synced ? SyncStatus.modified : siblingPayment.syncStatus,
                lastSyncedAt: siblingPayment.lastSyncedAt,
                groupId: siblingPayment.groupId
            )

            try await paymentRepository.savePayment(updatedSibling)
            log.info("✅ Sibling payment updated successfully: \(updatedSibling.name)", category: Self.logCategory)
        } catch {
            log.error("❌ Failed to update sibling payment: \(error.localizedDescription)", category: Self.logCategory)
            // Don't fail the whole operation if sibling update fails
        }
    }
}
