//
//  UpdatePaymentUseCase.swift
//  pagosApp
//
//  Use Case for updating an existing payment
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

/// Use case for updating an existing payment
final class UpdatePaymentUseCase {
    private let paymentRepository: PaymentRepositoryProtocol
    private let validator: PaymentValidator
    private let syncCalendarUseCase: SyncPaymentWithCalendarUseCase?
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "UpdatePaymentUseCase")

    init(
        paymentRepository: PaymentRepositoryProtocol,
        validator: PaymentValidator = PaymentValidator(),
        syncCalendarUseCase: SyncPaymentWithCalendarUseCase? = nil
    ) {
        self.paymentRepository = paymentRepository
        self.validator = validator
        self.syncCalendarUseCase = syncCalendarUseCase
    }

    /// Execute the update payment use case
    /// - Parameter payment: The payment entity to update
    /// - Returns: Result with updated payment or error
    func execute(_ payment: Payment) async -> Result<Payment, PaymentError> {
        logger.info("🔄 Updating payment: \(payment.name)")

        // 1. Validate payment
        do {
            try validator.validate(payment)
        } catch let error as PaymentError {
            logger.error("❌ Validation failed: \(error.errorCode)")
            return .failure(error)
        } catch {
            logger.error("❌ Unexpected validation error: \(error.localizedDescription)")
            return .failure(.unknown(error.localizedDescription))
        }

        // 2. Update sync status if needed
        var updatedPayment = payment
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
        }

        // 3. Save the main payment to repository
        do {
            try await paymentRepository.savePayment(updatedPayment)
            logger.info("✅ Payment updated successfully: \(payment.name)")
        } catch {
            logger.error("❌ Failed to update payment: \(error.localizedDescription)")
            return .failure(.updateFailed(error.localizedDescription))
        }

        // 4. If this payment is part of a group, update the sibling payment with shared fields
        if let groupId = payment.groupId {
            logger.info("🔗 Payment is part of group: \(groupId)")
            await updateSiblingPayment(groupId: groupId, updatedPayment: updatedPayment)
        }

        // 5. Sync with calendar (if use case is available)
        if let syncUseCase = syncCalendarUseCase {
            await withCheckedContinuation { continuation in
                syncUseCase.requestAccess { granted in
                    if granted {
                        Task {
                            // Sync payment with calendar
                            let syncResult = await syncUseCase.execute(updatedPayment)
                            switch syncResult {
                            case .success(let syncedPayment):
                                self.logger.info("✅ Payment synced with calendar: \(syncedPayment.name)")
                            case .failure(let error):
                                self.logger.warning("⚠️ Failed to sync payment with calendar: \(error.errorCode)")
                                // Don't fail the whole operation if calendar sync fails
                            }
                            continuation.resume()
                        }
                    } else {
                        self.logger.info("ℹ️ Calendar access denied, skipping calendar sync")
                        continuation.resume()
                    }
                }
            }
        }

        // 6. Notify that payments have been updated so UI can refresh
        NotificationCenter.default.post(name: NSNotification.Name("PaymentsDidSync"), object: nil)
        logger.debug("📢 Posted PaymentsDidSync notification")

        return .success(updatedPayment)
    }

    /// Update sibling payment in the same group with shared fields
    private func updateSiblingPayment(groupId: UUID, updatedPayment: Payment) async {
        do {
            // Get all local payments in the group
            let allPayments = try await paymentRepository.getAllLocalPayments()
            let groupPayments = allPayments.filter { $0.groupId == groupId && $0.id != updatedPayment.id }

            guard let siblingPayment = groupPayments.first else {
                logger.debug("ℹ️ No sibling payment found in group")
                return
            }

            logger.info("🔄 Updating sibling payment: \(siblingPayment.name)")

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
            logger.info("✅ Sibling payment updated successfully: \(updatedSibling.name)")
        } catch {
            logger.error("❌ Failed to update sibling payment: \(error.localizedDescription)")
            // Don't fail the whole operation if sibling update fails
        }
    }
}
