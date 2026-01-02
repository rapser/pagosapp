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
        logger.info("📤 Uploading local payment changes")

        do {
            // 1. Get current user ID
            let userId = try await syncRepository.getCurrentUserId()

            // 2. Get payments pending sync
            let pendingPayments = try await syncRepository.getPendingPayments()
            logger.info("Found \(pendingPayments.count) payments to upload")

            guard !pendingPayments.isEmpty else {
                logger.info("✅ No local changes to upload")
                return .success(())
            }

            // 3. Upload to remote
            try await syncRepository.uploadPayments(pendingPayments, userId: userId)

            logger.info("✅ Uploaded \(pendingPayments.count) payments successfully")
            return .success(())
        } catch let error as PaymentSyncError {
            logger.error("❌ Upload failed: \(error.errorCode)")
            return .failure(error)
        } catch {
            logger.error("❌ Upload failed: \(error.localizedDescription)")
            return .failure(.uploadFailed(error.localizedDescription))
        }
    }
}
