//
//  SyncRemindersUseCase.swift
//  pagosApp
//
//  Use case for full reminder synchronization (upload + download).
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

final class SyncRemindersUseCase {
    private let uploadUseCase: UploadReminderChangesUseCase
    private let downloadUseCase: DownloadReminderChangesUseCase
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "SyncRemindersUseCase")

    init(uploadUseCase: UploadReminderChangesUseCase, downloadUseCase: DownloadReminderChangesUseCase) {
        self.uploadUseCase = uploadUseCase
        self.downloadUseCase = downloadUseCase
    }

    func execute() async -> Result<Void, ReminderSyncError> {
        logger.info("🔄 Starting full reminder synchronization")
        let uploadResult = await uploadUseCase.execute()
        if case .failure(let error) = uploadResult {
            logger.error("❌ Upload failed: \(error.errorCode)")
            return .failure(error)
        }
        let downloadResult = await downloadUseCase.execute()
        if case .failure(let error) = downloadResult {
            logger.error("❌ Download failed: \(error.errorCode)")
            return .failure(error)
        }
        logger.info("✅ Full reminder synchronization completed successfully")
        return .success(())
    }
}
