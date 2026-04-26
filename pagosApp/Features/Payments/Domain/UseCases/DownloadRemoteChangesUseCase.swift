//
//  DownloadRemoteChangesUseCase.swift
//  pagosApp
//
//  Use Case for downloading remote payment changes
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case for downloading remote payment changes and merging with local
@MainActor
final class DownloadRemoteChangesUseCase {
    private static let logCategory = "DownloadRemoteChangesUseCase"

    private let syncRepository: PaymentSyncRepositoryProtocol
    private let paymentRepository: PaymentRepositoryProtocol
    private let log: DomainLogWriter
    private let keepLocalWhenPendingSyncStatuses: Set<SyncStatus> = [.local, .modified, .error]

    init(
        syncRepository: PaymentSyncRepositoryProtocol,
        paymentRepository: PaymentRepositoryProtocol,
        log: DomainLogWriter
    ) {
        self.syncRepository = syncRepository
        self.paymentRepository = paymentRepository
        self.log = log
    }

    /// Execute download of remote changes
    /// - Returns: Result with success or sync error
    func execute() async -> Result<Void, PaymentSyncError> {
        do {
            let userId = try await syncRepository.getCurrentUserId()
            let remotePayments = try await syncRepository.downloadPayments(userId: userId)
            let localPayments = try await paymentRepository.getAllLocalPayments()

            for remotePayment in remotePayments {
                if let existingPayment = localPayments.first(where: { $0.id == remotePayment.id }) {
                    // Merge policy: server-wins by default, but preserve any local pending changes.
                    if !keepLocalWhenPendingSyncStatuses.contains(existingPayment.syncStatus) {
                        try await paymentRepository.savePayment(remotePayment)
                    }
                } else {
                    try await paymentRepository.savePayment(remotePayment)
                }
            }

            return .success(())
        } catch let error as PaymentSyncError {
            return .failure(error)
        } catch {
            log.error("Download failed: \(error.localizedDescription)", category: Self.logCategory)
            return .failure(.downloadFailed(error.localizedDescription))
        }
    }
}
