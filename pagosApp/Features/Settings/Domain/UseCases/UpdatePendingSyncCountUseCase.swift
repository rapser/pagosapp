//
//  UpdatePendingSyncCountUseCase.swift
//  pagosApp
//
//  Use Case for updating pending sync count
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use Case for updating pending sync count
final class UpdatePendingSyncCountUseCase {
    private let syncRepository: SettingsSyncRepositoryProtocol

    init(syncRepository: SettingsSyncRepositoryProtocol) {
        self.syncRepository = syncRepository
    }

    func execute() async {
        await syncRepository.updatePendingSyncCount()
    }
}
