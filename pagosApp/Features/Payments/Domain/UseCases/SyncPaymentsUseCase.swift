//
//  SyncPaymentsUseCase.swift
//  pagosApp
//
//  Use Case for synchronizing payments (upload + download)
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case for full payment synchronization
@MainActor
final class SyncPaymentsUseCase {
    private let uploadUseCase: UploadLocalChangesUseCase
    private let downloadUseCase: DownloadRemoteChangesUseCase

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
        let uploadResult = await uploadUseCase.execute()
        if case .failure(let error) = uploadResult { return .failure(error) }
        let downloadResult = await downloadUseCase.execute()
        if case .failure(let error) = downloadResult { return .failure(error) }
        return .success(())
    }
}
