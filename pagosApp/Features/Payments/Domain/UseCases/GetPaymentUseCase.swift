//
//  GetPaymentUseCase.swift
//  pagosApp
//
//  Use Case for fetching a single payment by ID
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

/// Use case for fetching a single payment by ID
final class GetPaymentUseCase {
    private let paymentRepository: PaymentRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "GetPaymentUseCase")

    init(paymentRepository: PaymentRepositoryProtocol) {
        self.paymentRepository = paymentRepository
    }

    /// Execute get payment by ID
    /// - Parameter id: The payment ID
    /// - Returns: Result with payment or error
    func execute(id: UUID) async -> Result<Payment?, PaymentError> {
        logger.debug("📱 Fetching payment: \(id)")

        do {
            let payment = try await paymentRepository.getLocalPayment(id: id)
            if let payment = payment {
                logger.debug("✅ Found payment: \(payment.name)")
            } else {
                logger.debug("❌ Payment not found: \(id)")
            }
            return .success(payment)
        } catch {
            logger.error("❌ Failed to fetch payment: \(error.localizedDescription)")
            return .failure(.unknown(error.localizedDescription))
        }
    }
}
