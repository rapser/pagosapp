//
//  GetPaymentHistoryUseCase.swift
//  pagosApp
//
//  Use Case for retrieving payment history with filtering
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use Case for retrieving payment history with filters
final class GetPaymentHistoryUseCase {
    private let historyRepository: HistoryRepositoryProtocol

    init(historyRepository: HistoryRepositoryProtocol) {
        self.historyRepository = historyRepository
    }

    func execute(filter: PaymentHistoryFilter) async -> Result<[Payment], PaymentError> {
        do {
            let payments = try await historyRepository.getPaymentHistory(filter: filter)
            return .success(payments)
        } catch {
            return .failure(.unknown("Failed to fetch payment history"))
        }
    }
}
