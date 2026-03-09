//
//  GetAllPaymentsUseCase.swift
//  pagosApp
//
//  Use Case for fetching all local payments
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

/// Use case for fetching all local payments
final class GetAllPaymentsUseCase {
    private let paymentRepository: PaymentRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "GetAllPaymentsUseCase")

    init(paymentRepository: PaymentRepositoryProtocol) {
        self.paymentRepository = paymentRepository
    }

    /// Execute get all payments
    /// - Returns: Result with array of payments or error
    func execute() async -> Result<[Payment], PaymentError> {
        logger.info("📋 [USE_CASE] GetAllPaymentsUseCase.execute() called")

        do {
            let payments = try await paymentRepository.getAllLocalPayments()
            logger.info("📋 [USE_CASE] ✅ Repository returned \(payments.count) payments")
            return .success(payments)
        } catch {
            logger.error("📋 [USE_CASE] ❌ Repository failed: \(error.localizedDescription)")
            return .failure(.unknown(error.localizedDescription))
        }
    }
}
