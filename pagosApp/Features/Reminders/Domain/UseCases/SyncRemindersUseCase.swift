//
//  SyncRemindersUseCase.swift
//  pagosApp
//
//  Use case for full reminder synchronization (upload + download).
//  Clean Architecture - Domain Layer
//

import Foundation

final class SyncRemindersUseCase {
    private let uploadUseCase: UploadReminderChangesUseCase
    private let downloadUseCase: DownloadReminderChangesUseCase

    init(uploadUseCase: UploadReminderChangesUseCase, downloadUseCase: DownloadReminderChangesUseCase) {
        self.uploadUseCase = uploadUseCase
        self.downloadUseCase = downloadUseCase
    }

    func execute() async -> Result<Void, ReminderSyncError> {
        let uploadResult = await uploadUseCase.execute()
        if case .failure(let error) = uploadResult { return .failure(error) }
        let downloadResult = await downloadUseCase.execute()
        if case .failure(let error) = downloadResult { return .failure(error) }
        return .success(())
    }
}
