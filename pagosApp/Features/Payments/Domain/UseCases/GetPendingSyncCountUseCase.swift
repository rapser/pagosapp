//
//  GetPendingSyncCountUseCase.swift
//  pagosApp
//
//  Use Case for getting count of payments pending synchronization
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case for getting count of payments pending sync
@MainActor
final class GetPendingSyncCountUseCase {
    private let syncRepository: PaymentSyncRepositoryProtocol

    init(syncRepository: PaymentSyncRepositoryProtocol) {
        self.syncRepository = syncRepository
    }

    /// Execute get pending sync count
    /// - Returns: Number of payments pending synchronization
    func execute() async -> Int {
        do {
            return try await syncRepository.getPendingSyncCount()
        } catch {
            return 0
        }
    }
}
