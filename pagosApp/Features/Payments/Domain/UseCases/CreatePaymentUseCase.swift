//
//  CreatePaymentUseCase.swift
//  pagosApp
//
//  Use Case for creating a new payment
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

/// Use case for creating a new payment with validation and side effects
final class CreatePaymentUseCase {
    private let paymentRepository: PaymentRepositoryProtocol
    private let validator: PaymentValidator
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "CreatePaymentUseCase")

    init(paymentRepository: PaymentRepositoryProtocol, validator: PaymentValidator = PaymentValidator()) {
        self.paymentRepository = paymentRepository
        self.validator = validator
    }

    /// Execute the create payment use case
    /// - Parameter payment: The payment entity to create
    /// - Returns: Result with created payment or error
    func execute(_ payment: Payment) async -> Result<Payment, PaymentError> {
        logger.info("🔨 Creating payment: \(payment.name)")

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

        // 2. Set initial sync status
        let newPayment = payment
        // We need to ensure syncStatus is .local for new payments
        // Note: Payment is immutable, so repository will handle this

        // 3. Save to repository
        do {
            try await paymentRepository.savePayment(newPayment)
            logger.info("✅ Payment created successfully: \(payment.name)")

            // Notify that payments have been updated so UI can refresh
            NotificationCenter.default.post(name: NSNotification.Name("PaymentsDidSync"), object: nil)
            logger.debug("📢 Posted PaymentsDidSync notification")

            return .success(newPayment)
        } catch {
            logger.error("❌ Failed to create payment: \(error.localizedDescription)")
            return .failure(.saveFailed(error.localizedDescription))
        }
    }
}
