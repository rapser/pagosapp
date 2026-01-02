//
//  DownloadRemoteChangesUseCase.swift
//  pagosApp
//
//  Use Case for downloading remote payment changes
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

/// Use case for downloading remote payment changes and merging with local
final class DownloadRemoteChangesUseCase {
    private let syncRepository: PaymentSyncRepositoryProtocol
    private let paymentRepository: PaymentRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "DownloadRemoteChangesUseCase")

    init(
        syncRepository: PaymentSyncRepositoryProtocol,
        paymentRepository: PaymentRepositoryProtocol
    ) {
        self.syncRepository = syncRepository
        self.paymentRepository = paymentRepository
    }

    /// Execute download of remote changes
    /// - Returns: Result with success or sync error
    func execute() async -> Result<Void, PaymentSyncError> {
        logger.info("📥 Downloading remote payment changes")

        do {
            // 1. Get current user ID
            let userId = try await syncRepository.getCurrentUserId()

            // 2. Download remote payments
            let remotePayments = try await syncRepository.downloadPayments(userId: userId)
            logger.info("Downloaded \(remotePayments.count) payments from remote")

            // 3. Get local payments
            let localPayments = try await paymentRepository.getAllLocalPayments()

            // 4. Merge remote with local (upsert logic)
            for remotePayment in remotePayments {
                if let existingPayment = localPayments.first(where: { $0.id == remotePayment.id }) {
                    // Only update if not locally modified
                    if existingPayment.syncStatus != .modified && existingPayment.syncStatus != .local {
                        try await paymentRepository.savePayment(remotePayment)
                        logger.info("Updated local payment from remote: \(remotePayment.name)")
                    } else {
                        logger.info("Skipped updating \(remotePayment.name) - has local modifications")
                    }
                } else {
                    // New payment from remote
                    try await paymentRepository.savePayment(remotePayment)
                    logger.info("Inserted new payment from remote: \(remotePayment.name)")
                }
            }

            logger.info("✅ Downloaded and merged \(remotePayments.count) payments successfully")
            return .success(())
        } catch let error as PaymentSyncError {
            logger.error("❌ Download failed: \(error.errorCode)")
            return .failure(error)
        } catch {
            logger.error("❌ Download failed: \(error.localizedDescription)")
            return .failure(.downloadFailed(error.localizedDescription))
        }
    }
}
