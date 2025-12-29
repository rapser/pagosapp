//
//  PerformSyncUseCase.swift
//  pagosApp
//
//  Use Case for performing payment synchronization
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use Case for performing payment synchronization
final class PerformSyncUseCase {
    private let syncRepository: SettingsSyncRepositoryProtocol

    init(syncRepository: SettingsSyncRepositoryProtocol) {
        self.syncRepository = syncRepository
    }

    func execute() async throws {
        try await syncRepository.performSync()
    }
}
