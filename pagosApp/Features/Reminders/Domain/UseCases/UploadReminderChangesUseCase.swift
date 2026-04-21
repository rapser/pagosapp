//
//  UploadReminderChangesUseCase.swift
//  pagosApp
//
//  Use case for uploading local reminder changes to Supabase.
//  Clean Architecture - Domain Layer
//

import Foundation

final class UploadReminderChangesUseCase {
    private static let logCategory = "UploadReminderChangesUseCase"

    private let syncRepository: ReminderSyncRepositoryProtocol
    private let log: DomainLogWriter

    init(syncRepository: ReminderSyncRepositoryProtocol, log: DomainLogWriter) {
        self.syncRepository = syncRepository
        self.log = log
    }

    func execute() async -> Result<Void, ReminderSyncError> {
        log.info("📤 Uploading local reminder changes", category: Self.logCategory)
        do {
            let userId = try await syncRepository.getCurrentUserId()
            let pending = try await syncRepository.getPendingReminders()
            log.info("Found \(pending.count) reminders to upload", category: Self.logCategory)
            guard !pending.isEmpty else {
                log.info("✅ No local reminder changes to upload", category: Self.logCategory)
                return .success(())
            }
            try await syncRepository.uploadReminders(pending, userId: userId)
            log.info("✅ Uploaded \(pending.count) reminders successfully", category: Self.logCategory)
            return .success(())
        } catch let error as ReminderSyncError {
            log.error("❌ Upload failed: \(error.errorCode)", category: Self.logCategory)
            return .failure(error)
        } catch {
            log.error("❌ Upload failed: \(error.localizedDescription)", category: Self.logCategory)
            return .failure(.uploadFailed(error.localizedDescription))
        }
    }
}
