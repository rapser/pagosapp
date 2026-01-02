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
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "UpdatePaymentUseCase")

    init(paymentRepository: PaymentRepositoryProtocol, validator: PaymentValidator = PaymentValidator()) {
        self.paymentRepository = paymentRepository
        self.validator = validator
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

        // 3. Save to repository
        do {
            try await paymentRepository.savePayment(updatedPayment)
            logger.info("✅ Payment updated successfully: \(payment.name)")
            return .success(updatedPayment)
        } catch {
            logger.error("❌ Failed to update payment: \(error.localizedDescription)")
            return .failure(.updateFailed(error.localizedDescription))
        }
    }
}
