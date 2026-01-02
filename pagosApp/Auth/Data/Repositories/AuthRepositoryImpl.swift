//
//  AuthRepositoryImpl.swift
//  pagosApp
//
//  Implementation of Auth repository (Clean Architecture)
//  Clean Architecture - Data Layer
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "AuthRepositoryImpl")

/// Implementation of AuthRepositoryProtocol
/// Coordinates between remote and local data sources
@MainActor
final class AuthRepositoryImpl: AuthRepositoryProtocol {
    private let remoteDataSource: AuthRemoteDataSource
    private let localDataSource: AuthLocalDataSource
    private let mapper: SupabaseAuthDTOMapper

    init(
        remoteDataSource: AuthRemoteDataSource,
        localDataSource: AuthLocalDataSource,
        mapper: SupabaseAuthDTOMapper = SupabaseAuthDTOMapper()
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
        self.mapper = mapper
    }

    // MARK: - Authentication Operations

    func signUp(credentials: RegistrationCredentials) async -> Result<AuthSession, AuthError> {
        do {
            logger.info("📝 Signing up user")

            // Sign up via remote data source
            let sessionDTO = try await remoteDataSource.signUp(
                email: credentials.email,
                password: credentials.password,
                metadata: credentials.metadata
            )

            // Map to domain entity
            let session = mapper.toDomain(sessionDTO)

            // Save tokens locally
            let keychainDTO = KeychainAuthDTOMapper().toDTO(from: session)
            try localDataSource.saveTokens(keychainDTO)

            logger.info("✅ User signed up successfully")

            return .success(session)

        } catch let error as AuthError {
            logger.error("❌ Sign up failed: \(error.errorCode)")
            return .failure(error)
        } catch {
            logger.error("❌ Sign up failed: \(error.localizedDescription)")
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func signIn(credentials: LoginCredentials) async -> Result<AuthSession, AuthError> {
        do {
            logger.info("🔑 Signing in user")

            // Sign in via remote data source
            let sessionDTO = try await remoteDataSource.signIn(
                email: credentials.email,
                password: credentials.password
            )

            // Map to domain entity
            let session = mapper.toDomain(sessionDTO)

            // Save tokens locally
            let keychainDTO = KeychainAuthDTOMapper().toDTO(from: session)
            try localDataSource.saveTokens(keychainDTO)

            logger.info("✅ User signed in successfully")

            return .success(session)

        } catch let error as AuthError {
            logger.error("❌ Sign in failed: \(error.errorCode)")
            return .failure(error)
        } catch {
            logger.error("❌ Sign in failed: \(error.localizedDescription)")
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func signOut() async -> Result<Void, AuthError> {
        logger.info("🚪 Signing out user")

        // Sign out from remote (best effort - don't fail if offline)
        try? await remoteDataSource.signOut()

        // Clear local tokens
        localDataSource.clearTokens()

        logger.info("✅ User signed out successfully")

        return .success(())
    }

    func getCurrentSession() async -> AuthSession? {
        do {
            logger.debug("🔍 Getting current session")

            // Try to get session from remote
            if let sessionDTO = try await remoteDataSource.getCurrentSession() {
                let session = mapper.toDomain(sessionDTO)
                logger.debug("✅ Session retrieved from remote")
                return session
            }

            logger.debug("⚠️ No remote session found")
            return nil

        } catch {
            logger.debug("⚠️ Failed to get remote session: \(error.localizedDescription)")
            return nil
        }
    }

    func refreshSession(refreshToken: String) async -> Result<AuthSession, AuthError> {
        do {
            logger.info("🔄 Refreshing session")

            // Refresh session via remote
            let sessionDTO = try await remoteDataSource.refreshSession(refreshToken: refreshToken)

            // Map to domain entity
            let session = mapper.toDomain(sessionDTO)

            // Save new tokens locally
            let keychainDTO = KeychainAuthDTOMapper().toDTO(from: session)
            try localDataSource.saveTokens(keychainDTO)

            logger.info("✅ Session refreshed successfully")

            return .success(session)

        } catch let error as AuthError {
            logger.error("❌ Session refresh failed: \(error.errorCode)")
            return .failure(error)
        } catch {
            logger.error("❌ Session refresh failed: \(error.localizedDescription)")
            return .failure(.sessionExpired)
        }
    }

    // MARK: - Password Management

    func sendPasswordResetEmail(email: String) async -> Result<Void, AuthError> {
        do {
            logger.info("📧 Sending password reset email")

            try await remoteDataSource.sendPasswordResetEmail(email: email)

            logger.info("✅ Password reset email sent")

            return .success(())

        } catch let error as AuthError {
            logger.error("❌ Password reset email failed: \(error.errorCode)")
            return .failure(error)
        } catch {
            logger.error("❌ Password reset email failed: \(error.localizedDescription)")
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func resetPassword(token: String, newPassword: String) async -> Result<Void, AuthError> {
        do {
            logger.info("🔐 Resetting password")

            try await remoteDataSource.resetPassword(token: token, newPassword: newPassword)

            logger.info("✅ Password reset successfully")

            return .success(())

        } catch let error as AuthError {
            logger.error("❌ Password reset failed: \(error.errorCode)")
            return .failure(error)
        } catch {
            logger.error("❌ Password reset failed: \(error.localizedDescription)")
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func updateEmail(newEmail: String) async -> Result<Void, AuthError> {
        do {
            logger.info("📧 Updating email")

            try await remoteDataSource.updateEmail(newEmail: newEmail)

            logger.info("✅ Email updated successfully")

            return .success(())

        } catch let error as AuthError {
            logger.error("❌ Email update failed: \(error.errorCode)")
            return .failure(error)
        } catch {
            logger.error("❌ Email update failed: \(error.localizedDescription)")
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func updatePassword(newPassword: String) async -> Result<Void, AuthError> {
        do {
            logger.info("🔐 Updating password")

            try await remoteDataSource.updatePassword(newPassword: newPassword)

            logger.info("✅ Password updated successfully")

            return .success(())

        } catch let error as AuthError {
            logger.error("❌ Password update failed: \(error.errorCode)")
            return .failure(error)
        } catch {
            logger.error("❌ Password update failed: \(error.localizedDescription)")
            return .failure(.unknown(error.localizedDescription))
        }
    }

    // MARK: - Account Management

    func deleteAccount() async -> Result<Void, AuthError> {
        do {
            logger.info("🗑️ Deleting account")

            try await remoteDataSource.deleteAccount()

            // Clear local tokens
            localDataSource.clearTokens()

            logger.info("✅ Account deleted successfully")

            return .success(())

        } catch let error as AuthError {
            logger.error("❌ Account deletion failed: \(error.errorCode)")
            return .failure(error)
        } catch {
            logger.error("❌ Account deletion failed: \(error.localizedDescription)")
            return .failure(.unknown(error.localizedDescription))
        }
    }

    // MARK: - User Info

    func getCurrentUserId() async -> UUID? {
        guard let session = await getCurrentSession() else {
            return nil
        }

        return session.user.id
    }
}
