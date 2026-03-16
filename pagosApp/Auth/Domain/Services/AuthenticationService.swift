//
//  AuthenticationService.swift
//  pagosApp
//
//  High-level authentication service protocol that unifies auth operations
//  Clean Architecture - Domain Layer Service
//

import Foundation

// MARK: - Authentication Service Protocol

/// High-level service that unifies authentication operations
/// Reduces dependency injection complexity by providing a single auth facade
@MainActor
protocol AuthenticationServiceProtocol: AnyObject, Sendable {
    
    // MARK: - Session State
    
    /// Whether a user is currently authenticated
    var isAuthenticated: Bool { get }
    
    /// Whether biometric authentication is available
    var isBiometricAvailable: Bool { get async }
    
    /// The current authenticated user ID
    var currentUserId: UUID? { get async }
    
    // MARK: - Authentication Operations
    
    /// Perform email/password login
    func login(email: String, password: String) async -> Result<AuthSession, AuthError>
    
    /// Perform biometric authentication
    func loginWithBiometrics() async -> Result<AuthSession, AuthError>
    
    /// Register a new user
    func register(credentials: RegistrationCredentials) async -> Result<AuthSession, AuthError>
    
    /// Logout current user
    func logout() async -> Result<Void, AuthError>
    
    // MARK: - Session Management
    
    /// Check and restore session on app launch
    func checkInitialAuthState() async
    
    /// Ensure the session is still valid
    func ensureValidSession() async -> Result<Bool, AuthError>
    
    /// Verify the remote session is active
    func verifyRemoteSession() async -> Bool
    
    // MARK: - Password Management
    
    /// Request password reset
    func requestPasswordReset(email: String) async -> Result<Void, AuthError>
}

// MARK: - Authentication Service Implementation

/// Concrete implementation of AuthenticationServiceProtocol
/// Coordinates multiple use cases to provide unified auth experience
@MainActor
final class AuthenticationService: AuthenticationServiceProtocol {
    
    // MARK: - State
    
    private(set) var isAuthenticated: Bool = false
    
    // MARK: - Dependencies
    
    private let loginUseCase: LoginUseCase
    private let registerUseCase: RegisterUseCase
    private let biometricLoginUseCase: BiometricLoginUseCase
    private let logoutUseCase: LogoutUseCase
    private let ensureValidSessionUseCase: EnsureValidSessionUseCase
    private let getAuthStatusUseCase: GetAuthenticationStatusUseCase
    private let getCurrentUserIdUseCase: GetCurrentUserIdUseCase
    private let biometricRepository: BiometricRepositoryProtocol
    private let sessionRepository: SessionRepositoryProtocol
    private let passwordRecoveryUseCase: PasswordRecoveryUseCase
    
    // MARK: - Initialization
    
    init(
        loginUseCase: LoginUseCase,
        registerUseCase: RegisterUseCase,
        biometricLoginUseCase: BiometricLoginUseCase,
        logoutUseCase: LogoutUseCase,
        ensureValidSessionUseCase: EnsureValidSessionUseCase,
        getAuthStatusUseCase: GetAuthenticationStatusUseCase,
        getCurrentUserIdUseCase: GetCurrentUserIdUseCase,
        biometricRepository: BiometricRepositoryProtocol,
        sessionRepository: SessionRepositoryProtocol,
        passwordRecoveryUseCase: PasswordRecoveryUseCase
    ) {
        self.loginUseCase = loginUseCase
        self.registerUseCase = registerUseCase
        self.biometricLoginUseCase = biometricLoginUseCase
        self.logoutUseCase = logoutUseCase
        self.ensureValidSessionUseCase = ensureValidSessionUseCase
        self.getAuthStatusUseCase = getAuthStatusUseCase
        self.getCurrentUserIdUseCase = getCurrentUserIdUseCase
        self.biometricRepository = biometricRepository
        self.sessionRepository = sessionRepository
        self.passwordRecoveryUseCase = passwordRecoveryUseCase
    }
    
    // MARK: - AuthenticationServiceProtocol
    
    var isBiometricAvailable: Bool {
        get async {
            await biometricRepository.isBiometricAvailable
        }
    }
    
    var currentUserId: UUID? {
        get async {
            await getCurrentUserIdUseCase.execute()
        }
    }
    
    func login(email: String, password: String) async -> Result<AuthSession, AuthError> {
        let result = await loginUseCase.execute(email: email, password: password)
        if case .success = result {
            isAuthenticated = true
        }
        return result
    }
    
    func loginWithBiometrics() async -> Result<AuthSession, AuthError> {
        let result = await biometricLoginUseCase.execute()
        if case .success = result {
            isAuthenticated = true
        }
        return result
    }
    
    func register(credentials: RegistrationCredentials) async -> Result<AuthSession, AuthError> {
        let result = await registerUseCase.execute(
            email: credentials.email,
            password: credentials.password
        )
        if case .success = result {
            isAuthenticated = true
        }
        return result
    }
    
    func logout() async -> Result<Void, AuthError> {
        let result = await logoutUseCase.execute()
        if case .success = result {
            isAuthenticated = false
        }
        return result
    }
    
    func checkInitialAuthState() async {
        let isAuth = await getAuthStatusUseCase.execute()
        isAuthenticated = isAuth
    }
    
    func ensureValidSession() async -> Result<Bool, AuthError> {
        do {
            try await ensureValidSessionUseCase.execute()
            return .success(true)
        } catch let authError as AuthError {
            return .failure(authError)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }
    
    func verifyRemoteSession() async -> Bool {
        do {
            try await ensureValidSessionUseCase.execute()
            return true
        } catch {
            return false
        }
    }
    
    func requestPasswordReset(email: String) async -> Result<Void, AuthError> {
        await passwordRecoveryUseCase.sendPasswordReset(email: email)
    }
}