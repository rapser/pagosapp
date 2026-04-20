//
//  GetPaymentUseCase.swift
//  pagosApp
//
//  Use Case for fetching a single payment by ID
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case for fetching a single payment by ID
final class GetPaymentUseCase {
    private static let logCategory = "GetPaymentUseCase"

    private let paymentRepository: PaymentRepositoryProtocol
    private let log: DomainLogWriter

    init(paymentRepository: PaymentRepositoryProtocol, log: DomainLogWriter) {
        self.paymentRepository = paymentRepository
        self.log = log
    }

    /// Execute get payment by ID
    /// - Parameter id: The payment ID
    /// - Returns: Result with payment or error
    func execute(id: UUID) async -> Result<Payment?, PaymentError> {
        log.debug("📱 Fetching payment: \(id)", category: Self.logCategory)

        do {
            let payment = try await paymentRepository.getLocalPayment(id: id)
            if let payment = payment {
                log.debug("✅ Found payment: \(payment.name)", category: Self.logCategory)
            } else {
                log.debug("❌ Payment not found: \(id)", category: Self.logCategory)
            }
            return .success(payment)
        } catch {
            log.error("❌ Failed to fetch payment: \(error.localizedDescription)", category: Self.logCategory)
            return .failure(.unknown(error.localizedDescription))
        }
    }
}
