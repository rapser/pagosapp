//
//  SyncPaymentsUseCase.swift
//  pagosApp
//
//  Use Case for synchronizing payments (upload + download)
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

/// Use case for full payment synchronization
final class SyncPaymentsUseCase {
    private let uploadUseCase: UploadLocalChangesUseCase
    private let downloadUseCase: DownloadRemoteChangesUseCase
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "SyncPaymentsUseCase")

    init(
        uploadUseCase: UploadLocalChangesUseCase,
        downloadUseCase: DownloadRemoteChangesUseCase
    ) {
        self.uploadUseCase = uploadUseCase
        self.downloadUseCase = downloadUseCase
    }

    /// Execute full synchronization (upload local changes, then download remote changes)
    /// - Returns: Result with success or sync error
    func execute() async -> Result<Void, PaymentSyncError> {
        logger.info("🔄 Starting full payment synchronization")

        // 1. Upload local changes first
        let uploadResult = await uploadUseCase.execute()
        if case .failure(let error) = uploadResult {
            logger.error("❌ Upload failed: \(error.errorCode)")
            return .failure(error)
        }

        // 2. Download remote changes
        let downloadResult = await downloadUseCase.execute()
        if case .failure(let error) = downloadResult {
            logger.error("❌ Download failed: \(error.errorCode)")
            return .failure(error)
        }

        logger.info("✅ Full synchronization completed successfully")
        return .success(())
    }
}
