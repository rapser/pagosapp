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
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "DeletePaymentUseCase")

    init(paymentRepository: PaymentRepositoryProtocol) {
        self.paymentRepository = paymentRepository
    }

    /// Execute the delete payment use case
    /// - Parameter paymentId: The ID of the payment to delete
    /// - Returns: Result with success or error
    func execute(paymentId: UUID) async -> Result<Void, PaymentError> {
        logger.info("🗑️ Deleting payment: \(paymentId)")

        do {
            try await paymentRepository.deleteLocalPayment(id: paymentId)
            logger.info("✅ Payment deleted successfully: \(paymentId)")

            // Notify that payments have been updated so UI can refresh
            NotificationCenter.default.post(name: NSNotification.Name("PaymentsDidSync"), object: nil)
            logger.debug("📢 Posted PaymentsDidSync notification")

            return .success(())
        } catch {
            logger.error("❌ Failed to delete payment: \(error.localizedDescription)")
            return .failure(.deleteFailed(error.localizedDescription))
        }
    }
}
