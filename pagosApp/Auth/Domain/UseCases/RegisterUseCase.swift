//
//  RegisterUseCase.swift
//  pagosApp
//
//  Use case for user registration
//  Clean Architecture - Domain Layer
//

import Foundation

/// Use case for registering a new user
@MainActor
final class RegisterUseCase {
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

    /// Execute registration
    /// - Parameters:
    ///   - email: User email
    ///   - password: User password
    ///   - metadata: Optional user metadata
    /// - Returns: Result with AuthSession or AuthError
    func execute(email: String, password: String, metadata: [String: String]? = nil) async -> Result<AuthSession, AuthError> {
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
        let credentials = RegistrationCredentials(
            email: email,
            password: password,
            metadata: metadata
        )

        // Execute sign up
        let result = await authRepository.signUp(credentials: credentials)

        return result
    }
}
