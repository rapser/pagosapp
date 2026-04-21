//
//  LoginUseCase.swift
//  pagosApp
//
//  Use case for user login with email and password
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case for authenticating user with email and password
@MainActor
final class LoginUseCase {
    private let authRepository: AuthSessionRepositoryProtocol
    private let emailValidator: EmailValidator.Type
    private let loginAttemptTracker: LoginAttemptTracking

    init(
        authRepository: AuthSessionRepositoryProtocol,
        emailValidator: EmailValidator.Type = EmailValidator.self,
        loginAttemptTracker: LoginAttemptTracking
    ) {
        self.authRepository = authRepository
        self.emailValidator = emailValidator
        self.loginAttemptTracker = loginAttemptTracker
    }

    /// Execute login
    /// - Parameters:
    ///   - email: User email
    ///   - password: User password
    /// - Returns: Result with AuthSession or AuthError
    func execute(email: String, password: String) async -> Result<AuthSession, AuthError> {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate email format
        do {
            try emailValidator.validate(email)
        } catch {
            return .failure(error as? AuthError ?? .invalidEmail)
        }

        // Login does not enforce signup-style password rules (length/symbol/etc.); Supabase validates
        // credentials. Register/reset flows still use PasswordValidator.

        if let lockoutUntil = loginAttemptTracker.lockoutUntilIfActive(forNormalizedEmail: normalizedEmail),
           lockoutUntil > Date() {
            return .failure(.tooManyLoginAttempts(lockoutUntil: lockoutUntil))
        }

        // Create credentials
        let credentials = LoginCredentials(email: email, password: password)

        // Execute sign in
        let result = await authRepository.signIn(credentials: credentials)

        switch result {
        case .success(let session):
            loginAttemptTracker.recordSuccessfulLogin(forNormalizedEmail: normalizedEmail)
            return .success(session)
        case .failure(let error):
            if case .invalidCredentials = error {
                loginAttemptTracker.recordFailedPasswordAttempt(forNormalizedEmail: normalizedEmail)
            }
            return .failure(error)
        }
    }
}
