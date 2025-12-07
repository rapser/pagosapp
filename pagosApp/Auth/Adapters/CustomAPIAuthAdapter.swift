//
//  CustomAPIAuthAdapter.swift
//  pagosApp
//
//  Custom REST API implementation of AuthService (Example template)
//  Adapt this to match your backend API endpoints
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "CustomAPIAuthAdapter")

/// Custom API implementation of AuthService
/// Template for connecting to your own backend API
@MainActor
final class CustomAPIAuthAdapter: AuthService {
    private let baseURL: URL
    private let urlSession: URLSession
    
    init(baseURL: URL, urlSession: URLSession = .shared) {
        self.baseURL = baseURL
        self.urlSession = urlSession
        logger.info("🔧 CustomAPIAuthAdapter inicializado con base URL: \(baseURL.absoluteString)")
    }
    
    // MARK: - Sign Up
    
    func signUp(credentials: RegistrationCredentials) async throws -> AuthSession {
        let endpoint = baseURL.appendingPathComponent("/auth/register")
        
        let body: [String: Any] = [
            "email": credentials.email,
            "password": credentials.password,
            "metadata": credentials.metadata ?? [:]
        ]
        
        let request = try createRequest(url: endpoint, method: "POST", body: body)
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            try validateResponse(response)
            
            return try decodeAuthSession(from: data)
            
        } catch {
            logger.error("❌ Error en signUp: \(error.localizedDescription)")
            throw mapNetworkError(error)
        }
    }
    
    // MARK: - Sign In
    
    func signIn(credentials: LoginCredentials) async throws -> AuthSession {
        let endpoint = baseURL.appendingPathComponent("/auth/login")
        
        let body: [String: Any] = [
            "email": credentials.email,
            "password": credentials.password
        ]
        
        let request = try createRequest(url: endpoint, method: "POST", body: body)
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            try validateResponse(response)
            
            return try decodeAuthSession(from: data)
            
        } catch {
            logger.error("❌ Error en signIn: \(error.localizedDescription)")
            throw mapNetworkError(error)
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        let endpoint = baseURL.appendingPathComponent("/auth/logout")
        
        var request = try createRequest(url: endpoint, method: "POST", body: nil)
        try addAuthorizationHeader(to: &request)
        
        do {
            let (_, response) = try await urlSession.data(for: request)
            try validateResponse(response)
            
            logger.info("✅ Sign out exitoso")
            
        } catch {
            logger.error("❌ Error en signOut: \(error.localizedDescription)")
            throw mapNetworkError(error)
        }
    }
    
    // MARK: - Get Current Session
    
    func getCurrentSession() async throws -> AuthSession? {
        let endpoint = baseURL.appendingPathComponent("/auth/session")
        
        var request = try createRequest(url: endpoint, method: "GET", body: nil)
        try addAuthorizationHeader(to: &request)
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return nil
            }
            
            if httpResponse.statusCode == 401 {
                return nil
            }
            
            try validateResponse(response)
            return try decodeAuthSession(from: data)
            
        } catch {
            logger.debug("⚠️ No hay sesión activa")
            return nil
        }
    }
    
    // MARK: - Refresh Session
    
    func refreshSession(refreshToken: String) async throws -> AuthSession {
        let endpoint = baseURL.appendingPathComponent("/auth/refresh")
        
        let body: [String: Any] = [
            "refreshToken": refreshToken
        ]
        
        let request = try createRequest(url: endpoint, method: "POST", body: body)
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            try validateResponse(response)
            
            return try decodeAuthSession(from: data)
            
        } catch {
            logger.error("❌ Error al refrescar sesión: \(error.localizedDescription)")
            throw AuthError.sessionExpired
        }
    }
    
    // MARK: - Password Reset
    
    func sendPasswordResetEmail(email: String) async throws {
        let endpoint = baseURL.appendingPathComponent("/auth/password-reset")
        
        let body: [String: Any] = [
            "email": email
        ]
        
        let request = try createRequest(url: endpoint, method: "POST", body: body)
        
        do {
            let (_, response) = try await urlSession.data(for: request)
            try validateResponse(response)
            
            logger.info("✅ Email de recuperación enviado")
            
        } catch {
            logger.error("❌ Error al enviar email: \(error.localizedDescription)")
            throw mapNetworkError(error)
        }
    }
    
    func resetPassword(token: String, newPassword: String) async throws {
        let endpoint = baseURL.appendingPathComponent("/auth/password-reset/confirm")
        
        let body: [String: Any] = [
            "token": token,
            "newPassword": newPassword
        ]
        
        let request = try createRequest(url: endpoint, method: "POST", body: body)
        
        do {
            let (_, response) = try await urlSession.data(for: request)
            try validateResponse(response)
            
            logger.info("✅ Contraseña actualizada")
            
        } catch {
            logger.error("❌ Error al actualizar contraseña: \(error.localizedDescription)")
            throw mapNetworkError(error)
        }
    }
    
    // MARK: - Update User
    
    func updateEmail(newEmail: String) async throws {
        let endpoint = baseURL.appendingPathComponent("/auth/email")
        
        let body: [String: Any] = [
            "email": newEmail
        ]
        
        var request = try createRequest(url: endpoint, method: "PUT", body: body)
        try addAuthorizationHeader(to: &request)
        
        do {
            let (_, response) = try await urlSession.data(for: request)
            try validateResponse(response)
            
            logger.info("✅ Email actualizado")
            
        } catch {
            logger.error("❌ Error al actualizar email: \(error.localizedDescription)")
            throw mapNetworkError(error)
        }
    }
    
    func updatePassword(newPassword: String) async throws {
        let endpoint = baseURL.appendingPathComponent("/auth/password")
        
        let body: [String: Any] = [
            "password": newPassword
        ]
        
        var request = try createRequest(url: endpoint, method: "PUT", body: body)
        try addAuthorizationHeader(to: &request)
        
        do {
            let (_, response) = try await urlSession.data(for: request)
            try validateResponse(response)
            
            logger.info("✅ Contraseña actualizada")
            
        } catch {
            logger.error("❌ Error al actualizar contraseña: \(error.localizedDescription)")
            throw mapNetworkError(error)
        }
    }
    
    // MARK: - Delete Account
    
    func deleteAccount() async throws {
        let endpoint = baseURL.appendingPathComponent("/auth/account")
        
        var request = try createRequest(url: endpoint, method: "DELETE", body: nil)
        try addAuthorizationHeader(to: &request)
        
        do {
            let (_, response) = try await urlSession.data(for: request)
            try validateResponse(response)
            
            logger.warning("🗑️ Cuenta eliminada")
            
        } catch {
            logger.error("❌ Error al eliminar cuenta: \(error.localizedDescription)")
            throw mapNetworkError(error)
        }
    }
    
    // MARK: - Private Helpers
    
    private func createRequest(url: URL, method: String, body: [String: Any]?) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        return request
    }
    
    private func addAuthorizationHeader(to request: inout URLRequest) throws {
        guard let token = KeychainManager.getAccessToken() else {
            throw AuthError.sessionExpired
        }
        
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError(URLError(.badServerResponse))
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            switch httpResponse.statusCode {
            case 401:
                throw AuthError.invalidCredentials
            case 404:
                throw AuthError.userNotFound
            case 409:
                throw AuthError.emailAlreadyExists
            default:
                throw AuthError.unknown("Error HTTP: \(httpResponse.statusCode)")
            }
        }
    }
    
    private func decodeAuthSession(from data: Data) throws -> AuthSession {
        // Adapt this structure to match your API response
        struct APIResponse: Codable {
            let accessToken: String
            let refreshToken: String
            let expiresIn: Int
            let user: APIUser
            
            struct APIUser: Codable {
                let id: String
                let email: String
                let emailVerified: Bool
                let createdAt: String
            }
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let response = try decoder.decode(APIResponse.self, from: data)
        
        let user = AuthUser(
            id: UUID(uuidString: response.user.id) ?? UUID(),
            email: response.user.email,
            emailConfirmed: response.user.emailVerified,
            createdAt: ISO8601DateFormatter().date(from: response.user.createdAt) ?? Date(),
            metadata: nil
        )
        
        return AuthSession(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(response.expiresIn)),
            user: user
        )
    }
    
    private func mapNetworkError(_ error: Error) -> AuthError {
        if let authError = error as? AuthError {
            return authError
        }
        
        return .networkError(error)
    }
}
