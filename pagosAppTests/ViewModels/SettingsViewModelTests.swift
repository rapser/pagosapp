//
//  SettingsViewModelTests.swift
//  pagosAppTests
//
//  Unit tests for SettingsViewModel.
//

import Foundation
import Testing
@testable import pagosApp

@Suite("SettingsViewModel")
@MainActor
struct SettingsViewModelTests {
    let syncRepository = MockSettingsSyncRepository()
    let bus = SpyEventBus()
    let sut: SettingsViewModel

    init() {
        let performSyncUseCase = PerformSyncUseCase(syncRepository: syncRepository)
        let clearLocalDatabaseUseCase = ClearLocalDatabaseUseCase(syncRepository: syncRepository)
        let updatePendingSyncCountUseCase = UpdatePendingSyncCountUseCase(syncRepository: syncRepository)
        let getSyncStatusUseCase = GetSyncStatusUseCase(syncRepository: syncRepository)

        let authRepository = MockAuthSessionRepository()
        let sessionRepository = MockSessionRepository()
        let logoutUseCase = LogoutUseCase(
            authRepository: authRepository,
            sessionRepository: sessionRepository
        )
        let deleteLocalProfileUseCase = DeleteLocalProfileUseCase(
            userProfileRepository: MockUserProfileRepository(),
            log: NullLog()
        )
        let clearBiometricCredentialsUseCase = ClearBiometricCredentialsUseCase(
            biometricCredentialsDataSource: MockBiometricCredentialsDataSource(),
            log: NullLog()
        )
        let unlinkDeviceUseCase = UnlinkDeviceUseCase(
            logoutUseCase: logoutUseCase,
            clearLocalDatabaseUseCase: clearLocalDatabaseUseCase,
            deleteLocalProfileUseCase: deleteLocalProfileUseCase,
            clearBiometricCredentialsUseCase: clearBiometricCredentialsUseCase,
            sessionRepository: sessionRepository,
            log: NullLog()
        )

        sut = SettingsViewModel(
            performSyncUseCase: performSyncUseCase,
            clearLocalDatabaseUseCase: clearLocalDatabaseUseCase,
            updatePendingSyncCountUseCase: updatePendingSyncCountUseCase,
            getSyncStatusUseCase: getSyncStatusUseCase,
            logoutUseCase: logoutUseCase,
            unlinkDeviceUseCase: unlinkDeviceUseCase,
            eventBus: bus
        )
    }

    @Test func paymentEvent_updatesPendingSyncCount() async {
        syncRepository.pendingSyncCount = 3

        await Task.yield()
        bus.publish(PaymentUpdatedEvent(paymentId: UUID()))
        try? await Task.sleep(nanoseconds: 50_000_000)

        #expect(syncRepository.updatePendingSyncCountCallCount == 1)
        #expect(sut.pendingSyncCount == 3)
    }

    @Test func paymentsSyncedEvent_updatesPendingSyncCount() async {
        syncRepository.pendingSyncCount = 1

        await Task.yield()
        bus.publish(PaymentsSyncedEvent(syncedCount: 2))
        try? await Task.sleep(nanoseconds: 50_000_000)

        #expect(syncRepository.updatePendingSyncCountCallCount == 1)
        #expect(sut.pendingSyncCount == 1)
    }
}
