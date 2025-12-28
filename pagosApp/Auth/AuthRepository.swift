//
//  AuthRepository.swift
//  pagosApp
//
//  Repository that manages authentication through abstract AuthService
//  Modern iOS 18+ using @Observable macro
//

import Foundation
import Observation
import OSLog
import Supabase

private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "AuthRepository")

@MainActor
@Observable
final class AuthRepository {
    // MARK: - Observable Properties

    private(set) var currentUser: AuthUser?
    private(set) var isAuthenticated: Bool = false
    private(set) var isLoading: Bool = false

    // MARK: - Private Properties

    private let authService: any AuthService

    // MARK: - Internal Properties

    internal var authServiceInternal: any AuthService {
        return authService
    }

    var supabaseClient: SupabaseClient? {
        return (authService as? SupabaseAuthAdapter)?.supabaseClient
    }

    // MARK: - Initialization

    init(authService: any AuthService) {
        self.authService = authService

        Task {
            await checkExistingSession()
        }
    }

    // MARK: - Authentication Methods

    func register(email: String, password: String, metadata: [String: String]? = nil) async throws {
        isLoading = true
        defer { isLoading = false }

        try validateEmail(email)
        try validatePassword(password)

        let credentials = RegistrationCredentials(
            email: email,
            password: password,
            metadata: metadata
        )

        let session = try await authService.signUp(credentials: credentials)
        try saveSession(session)
        updateAuthenticationState(with: session.user)
    }

    func login(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        try validateEmail(email)

        let credentials = LoginCredentials(email: email, password: password)
        let session = try await authService.signIn(credentials: credentials)
        try saveSession(session)
        updateAuthenticationState(with: session.user)
    }

    func logout() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signOut()
        } catch {
            logger.error("Remote logout failed: \(error.localizedDescription)")
        }

        clearSession()
        clearAuthenticationState()
    }

    func sendPasswordReset(email: String) async throws {
        isLoading = true
        defer { isLoading = false }

        try validateEmail(email)
        try await authService.sendPasswordResetEmail(email: email)
    }

    func resetPassword(token: String, newPassword: String) async throws {
        isLoading = true
        defer { isLoading = false }

        try validatePassword(newPassword)
        try await authService.resetPassword(token: token, newPassword: newPassword)
    }

    func updateEmail(newEmail: String) async throws {
        isLoading = true
        defer { isLoading = false }

        try validateEmail(newEmail)
        try await authService.updateEmail(newEmail: newEmail)
        try await refreshSession()
    }

    func updatePassword(newPassword: String) async throws {
        isLoading = true
        defer { isLoading = false }

        try validatePassword(newPassword)
        try await authService.updatePassword(newPassword: newPassword)
    }

    func deleteAccount() async throws {
        isLoading = true
        defer { isLoading = false }

        try await authService.deleteAccount()
        clearSession()
        clearAuthenticationState()
    }

    // MARK: - Session Management

    private func checkExistingSession() async {
        if KeychainManager.getAccessToken() != nil,
           KeychainManager.getRefreshToken() != nil,
           KeychainManager.getUserId() != nil {
            isAuthenticated = true
        } else {
            clearAuthenticationState()
        }
    }

    func refreshSession() async throws {
        guard let refreshToken = KeychainManager.getRefreshToken() else {
            throw AuthError.sessionExpired
        }

        do {
            let session = try await authService.refreshSession(refreshToken: refreshToken)
            try saveSession(session)
            updateAuthenticationState(with: session.user)
        } catch {
            clearSession()
            clearAuthenticationState()
            throw AuthError.sessionExpired
        }
    }

    func ensureValidSession() async throws {
        guard let session = try await authService.getCurrentSession() else {
            throw AuthError.sessionExpired
        }

        if session.isExpired {
            guard let refreshToken = KeychainManager.getRefreshToken() else {
                throw AuthError.sessionExpired
            }

            do {
                let newSession = try await authService.refreshSession(refreshToken: refreshToken)
                try saveSession(newSession)
                updateAuthenticationState(with: newSession.user)
            } catch {
                throw AuthError.sessionExpired
            }
        }
    }

    // MARK: - Private Helpers

    private func saveSession(_ session: AuthSession) throws {
        try KeychainManager.saveAccessToken(session.accessToken)
        try KeychainManager.saveRefreshToken(session.refreshToken)
        try KeychainManager.saveUserId(session.user.id.uuidString)
    }

    private func clearSession() {
        KeychainManager.clearAllTokens()
    }

    private func updateAuthenticationState(with user: AuthUser) {
        self.currentUser = user
        self.isAuthenticated = true
    }

    private func clearAuthenticationState() {
        self.currentUser = nil
        self.isAuthenticated = false
    }

    // MARK: - Validation

    private func validateEmail(_ email: String) throws {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        guard emailPredicate.evaluate(with: email) else {
            throw AuthError.invalidEmail
        }
    }

    private func validatePassword(_ password: String) throws {
        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }
    }
}
