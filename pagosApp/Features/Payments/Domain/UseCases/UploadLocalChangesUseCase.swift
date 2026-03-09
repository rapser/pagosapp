//
//  UploadLocalChangesUseCase.swift
//  pagosApp
//
//  Use Case for uploading local payment changes to remote
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

/// Use case for uploading pending local payment changes
final class UploadLocalChangesUseCase {
    private let syncRepository: PaymentSyncRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "UploadLocalChangesUseCase")

    init(syncRepository: PaymentSyncRepositoryProtocol) {
        self.syncRepository = syncRepository
    }

    /// Execute upload of local changes
    /// - Returns: Result with success or sync error
    func execute() async -> Result<Void, PaymentSyncError> {
        do {
            let userId = try await syncRepository.getCurrentUserId()
            let pendingPayments = try await syncRepository.getPendingPayments()
            guard !pendingPayments.isEmpty else { return .success(()) }
            try await syncRepository.uploadPayments(pendingPayments, userId: userId)
            return .success(())
        } catch let error as PaymentSyncError {
            return .failure(error)
        } catch {
            logger.error("Upload failed: \(error.localizedDescription)")
            return .failure(.uploadFailed(error.localizedDescription))
        }
    }
}
