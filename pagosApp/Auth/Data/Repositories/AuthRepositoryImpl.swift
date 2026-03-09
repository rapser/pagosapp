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
            logger.info("\(L10n.Log.Auth.signUp)")

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

            logger.info("\(L10n.Log.Auth.signUpSuccess)")

            return .success(session)

        } catch let error as AuthError {
            logger.error("\(L10n.Log.Auth.signUpFailed(error.errorCode))")
            return .failure(error)
        } catch {
            logger.error("\(L10n.Log.Auth.signUpFailed(error.localizedDescription))")
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func signIn(credentials: LoginCredentials) async -> Result<AuthSession, AuthError> {
        do {
            logger.info("\(L10n.Log.Auth.signIn)")

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

            logger.info("\(L10n.Log.Auth.signInSuccess)")

            return .success(session)

        } catch let error as AuthError {
            logger.error("\(L10n.Log.Auth.signInFailed(error.errorCode))")
            return .failure(error)
        } catch {
            logger.error("\(L10n.Log.Auth.signInFailed(error.localizedDescription))")
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func signOut() async -> Result<Void, AuthError> {
        logger.info("\(L10n.Log.Auth.signOut)")

        // Sign out from remote (best effort - don't fail if offline)
        try? await remoteDataSource.signOut()

        // Clear local tokens
        localDataSource.clearTokens()

        logger.info("\(L10n.Log.Auth.signOutSuccess)")

        return .success(())
    }

    func getCurrentSession() async -> AuthSession? {
        do {
            logger.debug("\(L10n.Log.Auth.gettingSession)")

            // Try to get session from remote
            if let sessionDTO = try await remoteDataSource.getCurrentSession() {
                let session = mapper.toDomain(sessionDTO)
                logger.debug("\(L10n.Log.Auth.sessionRetrieved)")
                return session
            }

            logger.debug("\(L10n.Log.Auth.noRemoteSession)")
            return nil

        } catch {
            logger.debug("\(L10n.Log.Auth.sessionFailed(error.localizedDescription))")
            return nil
        }
    }

    func refreshSession(refreshToken: String) async -> Result<AuthSession, AuthError> {
        do {
            logger.info("\(L10n.Log.Auth.refreshingSession)")

            // Refresh session via remote
            let sessionDTO = try await remoteDataSource.refreshSession(refreshToken: refreshToken)

            // Map to domain entity
            let session = mapper.toDomain(sessionDTO)

            // Save new tokens locally
            let keychainDTO = KeychainAuthDTOMapper().toDTO(from: session)
            try localDataSource.saveTokens(keychainDTO)

            logger.info("\(L10n.Log.Auth.sessionRefreshed)")

            return .success(session)

        } catch let error as AuthError {
            logger.error("\(L10n.Log.Auth.sessionRefreshFailed(error.errorCode))")
            return .failure(error)
        } catch {
            logger.error("\(L10n.Log.Auth.sessionRefreshFailed(error.localizedDescription))")
            return .failure(.sessionExpired)
        }
    }

    // MARK: - Password Management

    func sendPasswordResetEmail(email: String) async -> Result<Void, AuthError> {
        do {
            logger.info("\(L10n.Log.Auth.passwordResetEmail)")

            try await remoteDataSource.sendPasswordResetEmail(email: email)

            logger.info("\(L10n.Log.Auth.passwordResetEmailSent)")

            return .success(())

        } catch let error as AuthError {
            logger.error("\(L10n.Log.Auth.passwordResetEmailFailed(error.errorCode))")
            return .failure(error)
        } catch {
            logger.error("\(L10n.Log.Auth.passwordResetEmailFailed(error.localizedDescription))")
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func resetPassword(token: String, newPassword: String) async -> Result<Void, AuthError> {
        do {
            logger.info("\(L10n.Log.Auth.resettingPassword)")

            try await remoteDataSource.resetPassword(token: token, newPassword: newPassword)

            logger.info("\(L10n.Log.Auth.passwordResetSuccess)")

            return .success(())

        } catch let error as AuthError {
            logger.error("\(L10n.Log.Auth.passwordResetFailed(error.errorCode))")
            return .failure(error)
        } catch {
            logger.error("\(L10n.Log.Auth.passwordResetFailed(error.localizedDescription))")
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func updateEmail(newEmail: String) async -> Result<Void, AuthError> {
        do {
            logger.info("\(L10n.Log.Auth.updatingEmail)")

            try await remoteDataSource.updateEmail(newEmail: newEmail)

            logger.info("\(L10n.Log.Auth.emailUpdated)")

            return .success(())

        } catch let error as AuthError {
            logger.error("\(L10n.Log.Auth.emailUpdateFailed(error.errorCode))")
            return .failure(error)
        } catch {
            logger.error("\(L10n.Log.Auth.emailUpdateFailed(error.localizedDescription))")
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func updatePassword(newPassword: String) async -> Result<Void, AuthError> {
        do {
            logger.info("\(L10n.Log.Auth.updatingPassword)")

            try await remoteDataSource.updatePassword(newPassword: newPassword)

            logger.info("\(L10n.Log.Auth.passwordUpdated)")

            return .success(())

        } catch let error as AuthError {
            logger.error("\(L10n.Log.Auth.passwordUpdateFailed(error.errorCode))")
            return .failure(error)
        } catch {
            logger.error("\(L10n.Log.Auth.passwordUpdateFailed(error.localizedDescription))")
            return .failure(.unknown(error.localizedDescription))
        }
    }

    // MARK: - Account Management

    func deleteAccount() async -> Result<Void, AuthError> {
        do {
            logger.info("\(L10n.Log.Auth.deletingAccount)")

            try await remoteDataSource.deleteAccount()

            // Clear local tokens
            localDataSource.clearTokens()

            logger.info("\(L10n.Log.Auth.accountDeleted)")

            return .success(())

        } catch let error as AuthError {
            logger.error("\(L10n.Log.Auth.accountDeletionFailed(error.errorCode))")
            return .failure(error)
        } catch {
            logger.error("\(L10n.Log.Auth.accountDeletionFailed(error.localizedDescription))")
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
