//
//  GetSyncStatusUseCase.swift
//  pagosApp
//
//  Use Case for getting sync status
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use Case for getting sync status (pending count and errors)
@MainActor
final class GetSyncStatusUseCase {
    private let syncRepository: SettingsSyncRepositoryProtocol

    init(syncRepository: SettingsSyncRepositoryProtocol) {
        self.syncRepository = syncRepository
    }

    func execute() -> SettingsSyncStatus {
        return SettingsSyncStatus(
            pendingSyncCount: syncRepository.pendingSyncCount,
            syncError: syncRepository.syncError
        )
    }
}

/// Domain model for settings sync status
struct SettingsSyncStatus {
    let pendingSyncCount: Int
    let syncError: PaymentSyncError?
}
