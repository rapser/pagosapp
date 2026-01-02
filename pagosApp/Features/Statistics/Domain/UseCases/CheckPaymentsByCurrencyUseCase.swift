//
//  CheckPaymentsByCurrencyUseCase.swift
//  pagosApp
//
//  Use Case to check if payments exist for specific currencies
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use Case to check if payments exist for specific currencies
final class CheckPaymentsByCurrencyUseCase {
    private let paymentRepository: PaymentRepositoryProtocol

    init(paymentRepository: PaymentRepositoryProtocol) {
        self.paymentRepository = paymentRepository
    }

    /// Check if payments exist for a specific currency
    /// - Parameter currency: Currency to check
    /// - Returns: true if at least one payment exists in this currency
    func execute(currency: Currency) async -> Bool {
        do {
            let payments = try await paymentRepository.getAllLocalPayments()
            return payments.contains { $0.currency == currency }
        } catch {
            return false
        }
    }

    /// Get available currencies (currencies with at least one payment)
    /// - Returns: Set of currencies that have payments
    func getAvailableCurrencies() async -> Set<Currency> {
        do {
            let payments = try await paymentRepository.getAllLocalPayments()
            return Set(payments.map { $0.currency })
        } catch {
            return []
        }
    }
}
