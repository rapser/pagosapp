//
//  GetAllPaymentsUseCase.swift
//  pagosApp
//
//  Use Case for fetching all local payments
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case for fetching all local payments
@MainActor
final class GetAllPaymentsUseCase {
    private static let logCategory = "GetAllPaymentsUseCase"

    private let paymentRepository: PaymentRepositoryProtocol
    private let log: DomainLogWriter

    init(paymentRepository: PaymentRepositoryProtocol, log: DomainLogWriter) {
        self.paymentRepository = paymentRepository
        self.log = log
    }

    /// Execute get all payments
    /// - Returns: Result with array of payments or error
    func execute() async -> Result<[Payment], PaymentError> {
        do {
            let payments = try await paymentRepository.getAllLocalPayments()
            return .success(payments)
        } catch {
            log.error("Failed to fetch payments: \(error.localizedDescription)", category: Self.logCategory)
            return .failure(.unknown(error.localizedDescription))
        }
    }
}
