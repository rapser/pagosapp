//
//  UploadReminderChangesUseCase.swift
//  pagosApp
//
//  Use case for uploading local reminder changes to Supabase.
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

final class UploadReminderChangesUseCase {
    private let syncRepository: ReminderSyncRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "UploadReminderChangesUseCase")

    init(syncRepository: ReminderSyncRepositoryProtocol) {
        self.syncRepository = syncRepository
    }

    func execute() async -> Result<Void, ReminderSyncError> {
        logger.info("📤 Uploading local reminder changes")
        do {
            let userId = try await syncRepository.getCurrentUserId()
            let pending = try await syncRepository.getPendingReminders()
            logger.info("Found \(pending.count) reminders to upload")
            guard !pending.isEmpty else {
                logger.info("✅ No local reminder changes to upload")
                return .success(())
            }
            try await syncRepository.uploadReminders(pending, userId: userId)
            logger.info("✅ Uploaded \(pending.count) reminders successfully")
            return .success(())
        } catch let error as ReminderSyncError {
            logger.error("❌ Upload failed: \(error.errorCode)")
            return .failure(error)
        } catch {
            logger.error("❌ Upload failed: \(error.localizedDescription)")
            return .failure(.uploadFailed(error.localizedDescription))
        }
    }
}
