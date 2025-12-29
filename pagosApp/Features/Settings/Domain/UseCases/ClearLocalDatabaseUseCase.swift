//
//  ClearLocalDatabaseUseCase.swift
//  pagosApp
//
//  Use Case for clearing local database
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use Case for clearing local database
final class ClearLocalDatabaseUseCase {
    private let syncRepository: SettingsSyncRepositoryProtocol

    init(syncRepository: SettingsSyncRepositoryProtocol) {
        self.syncRepository = syncRepository
    }

    func execute(force: Bool) async -> Bool {
        return await syncRepository.clearLocalDatabase(force: force)
    }
}
