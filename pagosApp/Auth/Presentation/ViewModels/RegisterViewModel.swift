//
//  RegisterViewModel.swift
//  pagosApp
//
//  ViewModel for Registration screen
//  Clean Architecture - Presentation Layer
//

import Foundation

/// ViewModel for Registration screen using Clean Architecture
@MainActor
@Observable
final class RegisterViewModel: BaseViewModel {
    // MARK: - UI State

    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var showPassword: Bool = false
    var showConfirmPassword: Bool = false

    // MARK: - Dependencies (Use Cases)

    private let registerUseCase: RegisterUseCase

    // MARK: - Callbacks

    var onRegistrationSuccess: ((AuthSession) -> Void)?

    // MARK: - Initialization

    init(registerUseCase: RegisterUseCase) {
        self.registerUseCase = registerUseCase
        super.init(category: "RegisterViewModel")
    }

    // MARK: - Actions

    /// Register new user
    func register() async {
        guard !isLoading else { return }
        logDebug("Attempting registration")

        guard password == confirmPassword else {
            setValidationError("Las contraseñas no coinciden")
            return
        }

        await withLoadingAndErrorHandling(
            operation: {
                let result = await self.registerUseCase.execute(
                    email: self.email,
                    password: self.password,
                    metadata: nil
                )
                
                switch result {
                case .success(let session):
                    self.logDebug("Registration successful")
                    self.onRegistrationSuccess?(session)
                    return session
                case .failure(let error):
                    self.logDebug("Registration failed: \(error.errorCode)")
                    throw error
                }
            },
            onError: { error in
                if let authError = error as? AuthError {
                    self.setError(AuthErrorMessageMapper.message(for: authError))
                }
            }
        )
    }

    // MARK: - Validation

    var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        PasswordValidator.isValid(password)
    }

    var passwordsMatch: Bool {
        password == confirmPassword
    }

    var isPasswordStrong: Bool {
        PasswordValidator.isValid(password)
    }
}
