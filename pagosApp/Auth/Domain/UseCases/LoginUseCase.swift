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
    private let authRepository: AuthRepositoryProtocol
    private let emailValidator: EmailValidator.Type
    private let passwordValidator: PasswordValidator.Type

    init(
        authRepository: AuthRepositoryProtocol,
        emailValidator: EmailValidator.Type = EmailValidator.self,
        passwordValidator: PasswordValidator.Type = PasswordValidator.self
    ) {
        self.authRepository = authRepository
        self.emailValidator = emailValidator
        self.passwordValidator = passwordValidator
    }

    /// Execute login
    /// - Parameters:
    ///   - email: User email
    ///   - password: User password
    /// - Returns: Result with AuthSession or AuthError
    func execute(email: String, password: String) async -> Result<AuthSession, AuthError> {
        // Validate email format
        do {
            try emailValidator.validate(email)
        } catch {
            return .failure(error as? AuthError ?? .invalidEmail)
        }

        // Validate password strength
        do {
            try passwordValidator.validate(password)
        } catch {
            return .failure(error as? AuthError ?? .weakPassword)
        }

        // Create credentials
        let credentials = LoginCredentials(email: email, password: password)

        // Execute sign in
        let result = await authRepository.signIn(credentials: credentials)

        return result
    }
}
