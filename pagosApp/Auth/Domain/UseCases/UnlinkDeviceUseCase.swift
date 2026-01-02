//
//  UnlinkDeviceUseCase.swift
//  pagosApp
//
//  Use Case: Unlink device and clear all local data
//  Clean Architecture - Domain Layer
//

import Foundation
import OSLog

/// Unlink device by clearing all local data (payments, profile, credentials, session)
/// This is a destructive operation that removes everything from this device
@MainActor
final class UnlinkDeviceUseCase {
    private let logoutUseCase: LogoutUseCase
    private let clearLocalDatabaseUseCase: ClearLocalDatabaseUseCase
    private let deleteLocalProfileUseCase: DeleteLocalProfileUseCase
    private let clearBiometricCredentialsUseCase: ClearBiometricCredentialsUseCase
    private let sessionRepository: SessionRepositoryProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "UnlinkDeviceUseCase")

    init(
        logoutUseCase: LogoutUseCase,
        clearLocalDatabaseUseCase: ClearLocalDatabaseUseCase,
        deleteLocalProfileUseCase: DeleteLocalProfileUseCase,
        clearBiometricCredentialsUseCase: ClearBiometricCredentialsUseCase,
        sessionRepository: SessionRepositoryProtocol
    ) {
        self.logoutUseCase = logoutUseCase
        self.clearLocalDatabaseUseCase = clearLocalDatabaseUseCase
        self.deleteLocalProfileUseCase = deleteLocalProfileUseCase
        self.clearBiometricCredentialsUseCase = clearBiometricCredentialsUseCase
        self.sessionRepository = sessionRepository
    }

    /// Execute: Unlink device by clearing all local data
    /// - Returns: Success or failure
    func execute() async -> Result<Void, AuthError> {
        logger.info("🔓 Unlinking device - clearing all local data")

        // 1. Logout from Supabase
        let logoutResult = await logoutUseCase.execute()
        if case .failure(let error) = logoutResult {
            logger.error("❌ Logout failed during unlink: \(error.errorCode)")
            return .failure(error)
        }

        // 2. Clear local payments database (force clear)
        let clearDBSuccess = await clearLocalDatabaseUseCase.execute(force: true)
        if !clearDBSuccess {
            logger.error("❌ Failed to clear local database")
            // Continue anyway - best effort
        }

        // 3. Delete local user profile
        let deleteProfileResult = await deleteLocalProfileUseCase.execute()
        if case .failure(let error) = deleteProfileResult {
            logger.error("❌ Failed to delete local profile: \(error.errorCode)")
            // Continue anyway - best effort
        }

        // 4. Clear biometric credentials
        clearBiometricCredentialsUseCase.execute()
        logger.info("✅ Cleared biometric credentials")

        // 5. Clear session
        await sessionRepository.clearSession()
        logger.info("✅ Cleared session")

        logger.info("✅ Device unlinked successfully - all local data cleared")
        return .success(())
    }
}
