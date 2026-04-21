//
//  UnlinkDeviceUseCase.swift
//  pagosApp
//
//  Use Case: Unlink device and clear all local data
//  Clean Architecture - Domain Layer
//

import Foundation

/// Unlink device by clearing all local data (payments, profile, credentials, session)
/// This is a destructive operation that removes everything from this device
@MainActor
final class UnlinkDeviceUseCase {
    private static let logCategory = "UnlinkDeviceUseCase"

    private let logoutUseCase: LogoutUseCase
    private let clearLocalDatabaseUseCase: ClearLocalDatabaseUseCase
    private let deleteLocalProfileUseCase: DeleteLocalProfileUseCase
    private let clearBiometricCredentialsUseCase: ClearBiometricCredentialsUseCase
    private let sessionRepository: SessionRepositoryProtocol
    private let log: DomainLogWriter

    init(
        logoutUseCase: LogoutUseCase,
        clearLocalDatabaseUseCase: ClearLocalDatabaseUseCase,
        deleteLocalProfileUseCase: DeleteLocalProfileUseCase,
        clearBiometricCredentialsUseCase: ClearBiometricCredentialsUseCase,
        sessionRepository: SessionRepositoryProtocol,
        log: DomainLogWriter
    ) {
        self.logoutUseCase = logoutUseCase
        self.clearLocalDatabaseUseCase = clearLocalDatabaseUseCase
        self.deleteLocalProfileUseCase = deleteLocalProfileUseCase
        self.clearBiometricCredentialsUseCase = clearBiometricCredentialsUseCase
        self.sessionRepository = sessionRepository
        self.log = log
    }

    /// Execute: Unlink device by clearing all local data
    /// - Returns: Success or failure
    func execute() async -> Result<Void, AuthError> {
        log.info("🔓 Unlinking device - clearing all local data", category: Self.logCategory)

        // 1. Logout from Supabase
        let logoutResult = await logoutUseCase.execute()
        if case .failure(let error) = logoutResult {
            log.error("❌ Logout failed during unlink: \(error.errorCode)", category: Self.logCategory)
            return .failure(error)
        }

        // 2. Clear local payments database (force clear)
        let clearDBSuccess = await clearLocalDatabaseUseCase.execute(force: true)
        if !clearDBSuccess {
            log.error("❌ Failed to clear local database", category: Self.logCategory)
            // Continue anyway - best effort
        }

        // 3. Delete local user profile
        let deleteProfileResult = await deleteLocalProfileUseCase.execute()
        if case .failure(let error) = deleteProfileResult {
            log.error("❌ Failed to delete local profile: \(error.errorCode)", category: Self.logCategory)
            // Continue anyway - best effort
        }

        // 4. Clear biometric credentials
        _ = clearBiometricCredentialsUseCase.execute()
        log.info("✅ Cleared biometric credentials", category: Self.logCategory)

        // 5. Clear session
        await sessionRepository.clearSession()
        log.info("✅ Cleared session", category: Self.logCategory)

        log.info("✅ Device unlinked successfully - all local data cleared", category: Self.logCategory)
        return .success(())
    }
}
