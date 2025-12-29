//
//  GetPendingSyncCountUseCase.swift
//  pagosApp
//
//  Use Case for getting count of payments pending synchronization
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

/// Use case for getting count of payments pending sync
final class GetPendingSyncCountUseCase {
    private let syncRepository: PaymentSyncRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "GetPendingSyncCountUseCase")

    init(syncRepository: PaymentSyncRepositoryProtocol) {
        self.syncRepository = syncRepository
    }

    /// Execute get pending sync count
    /// - Returns: Number of payments pending synchronization
    func execute() async -> Int {
        do {
            let count = try await syncRepository.getPendingSyncCount()
            logger.debug("📊 Pending sync count: \(count)")
            return count
        } catch {
            logger.error("❌ Failed to get pending sync count: \(error.localizedDescription)")
            return 0 // Safe default
        }
    }
}
