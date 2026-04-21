//
//  AuthRepositoryImpl.swift
//  pagosApp
//
//  Implementation of Auth repository (Clean Architecture)
//  Clean Architecture - Data Layer
//

import Foundation

/// Implementation of `AuthRepositoryProtocol` (session + credentials + account).
@MainActor
final class AuthRepositoryImpl: AuthRepositoryProtocol {
    private static let logCategory = "AuthRepositoryImpl"

    private let remoteDataSource: AuthRemoteDataSource
    private let localDataSource: AuthLocalDataSource
    private let mapper: SupabaseAuthDTOMapper
    private let log: DomainLogWriter

    init(
        remoteDataSource: AuthRemoteDataSource,
        localDataSource: AuthLocalDataSource,
        mapper: SupabaseAuthDTOMapper = SupabaseAuthDTOMapper(),
        log: DomainLogWriter
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
        self.mapper = mapper
        self.log = log
    }

    // MARK: - Authentication Operations

    func signUp(credentials: RegistrationCredentials) async -> Result<AuthSession, AuthError> {
        do {
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

            return .success(session)

        } catch let error as AuthError {
            log.error("\(L10n.Log.Auth.signUpFailed(error.errorCode))", category: Self.logCategory)
            return .failure(error)
        } catch {
            log.error("\(L10n.Log.Auth.signUpFailed(error.localizedDescription))", category: Self.logCategory)
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func signIn(credentials: LoginCredentials) async -> Result<AuthSession, AuthError> {
        do {
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

            return .success(session)

        } catch let error as AuthError {
            log.error("\(L10n.Log.Auth.signInFailed(error.errorCode))", category: Self.logCategory)
            return .failure(error)
        } catch {
            log.error("\(L10n.Log.Auth.signInFailed(error.localizedDescription))", category: Self.logCategory)
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func signOut() async -> Result<Void, AuthError> {
        do {
            try await remoteDataSource.signOut()
            localDataSource.clearTokens()
            return .success(())
        } catch {
            // Offline-first: local logout should still succeed, but remote signOut failure must be observable.
            let detail = L10n.Log.Generic.withContext("auth.signOut", error.localizedDescription)
            log.error("\(detail)", category: Self.logCategory)
            localDataSource.clearTokens()
            return .failure(.networkError(error.localizedDescription))
        }
    }

    func getCurrentSession() async -> AuthSession? {
        do {
            // Try to get session from remote
            if let sessionDTO = try await remoteDataSource.getCurrentSession() {
                let session = mapper.toDomain(sessionDTO)
                return session
            }

            return nil

        } catch {
            return nil
        }
    }

    func refreshSession(refreshToken: String) async -> Result<AuthSession, AuthError> {
        do {
            // Refresh session via remote
            let sessionDTO = try await remoteDataSource.refreshSession(refreshToken: refreshToken)

            // Map to domain entity
            let session = mapper.toDomain(sessionDTO)

            // Save new tokens locally
            let keychainDTO = KeychainAuthDTOMapper().toDTO(from: session)
            try localDataSource.saveTokens(keychainDTO)

            return .success(session)

        } catch let error as AuthError {
            log.error("\(L10n.Log.Auth.sessionRefreshFailed(error.errorCode))", category: Self.logCategory)
            return .failure(error)
        } catch {
            log.error("\(L10n.Log.Auth.sessionRefreshFailed(error.localizedDescription))", category: Self.logCategory)
            return .failure(.sessionExpired)
        }
    }

    // MARK: - Password Management

    func sendPasswordResetEmail(email: String) async -> Result<Void, AuthError> {
        do {
            try await remoteDataSource.sendPasswordResetEmail(email: email)

            return .success(())

        } catch let error as AuthError {
            log.error("\(L10n.Log.Auth.passwordResetEmailFailed(error.errorCode))", category: Self.logCategory)
            return .failure(error)
        } catch {
            log.error("\(L10n.Log.Auth.passwordResetEmailFailed(error.localizedDescription))", category: Self.logCategory)
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func resetPassword(token: String, newPassword: String) async -> Result<Void, AuthError> {
        do {
            try await remoteDataSource.resetPassword(token: token, newPassword: newPassword)

            return .success(())

        } catch let error as AuthError {
            log.error("\(L10n.Log.Auth.passwordResetFailed(error.errorCode))", category: Self.logCategory)
            return .failure(error)
        } catch {
            log.error("\(L10n.Log.Auth.passwordResetFailed(error.localizedDescription))", category: Self.logCategory)
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func updateEmail(newEmail: String) async -> Result<Void, AuthError> {
        do {
            try await remoteDataSource.updateEmail(newEmail: newEmail)

            return .success(())

        } catch let error as AuthError {
            log.error("\(L10n.Log.Auth.emailUpdateFailed(error.errorCode))", category: Self.logCategory)
            return .failure(error)
        } catch {
            log.error("\(L10n.Log.Auth.emailUpdateFailed(error.localizedDescription))", category: Self.logCategory)
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func updatePassword(newPassword: String) async -> Result<Void, AuthError> {
        do {
            try await remoteDataSource.updatePassword(newPassword: newPassword)

            return .success(())

        } catch let error as AuthError {
            log.error("\(L10n.Log.Auth.passwordUpdateFailed(error.errorCode))", category: Self.logCategory)
            return .failure(error)
        } catch {
            log.error("\(L10n.Log.Auth.passwordUpdateFailed(error.localizedDescription))", category: Self.logCategory)
            return .failure(.unknown(error.localizedDescription))
        }
    }

    // MARK: - Account Management

    func deleteAccount() async -> Result<Void, AuthError> {
        do {
            try await remoteDataSource.deleteAccount()

            // Clear local tokens
            localDataSource.clearTokens()

            return .success(())

        } catch let error as AuthError {
            log.error("\(L10n.Log.Auth.accountDeletionFailed(error.errorCode))", category: Self.logCategory)
            return .failure(error)
        } catch {
            log.error("\(L10n.Log.Auth.accountDeletionFailed(error.localizedDescription))", category: Self.logCategory)
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
