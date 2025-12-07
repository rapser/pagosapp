import Foundation
import Supabase

final class SupabaseAuthService: AuthenticationService {
    let client: SupabaseClient
    
    var isAuthenticated: Bool {
        get async {
            client.auth.currentUser != nil
        }
    }
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    func observeAuthState() async throws -> AsyncStream<Bool> {
        AsyncStream { continuation in
            Task {
                // Send initial state
                continuation.yield(client.auth.currentUser != nil)
                
                // Observe changes
                for await state in client.auth.authStateChanges {
                    switch state.event {
                    case .signedIn, .signedOut, .tokenRefreshed, .userUpdated, .passwordRecovery, .initialSession:
                        continuation.yield(client.auth.currentUser != nil)
                    case .userDeleted:
                        continuation.yield(false)
                    case .mfaChallengeVerified:
                        continuation.yield(client.auth.currentUser != nil)
                    }
                }
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            _ = try await client.auth.signIn(email: email, password: password)
        } catch let error as AuthError {
            let errorMessage = error.localizedDescription.lowercased()
            if errorMessage.contains("invalid login credentials") || errorMessage.contains("invalid email or password") {
                throw AuthenticationError.wrongCredentials
            } else {
                throw AuthenticationError.unknown(error)
            }
        } catch {
            throw AuthenticationError.unknown(error)
        }
    }
    
    func signOut() async throws {
        do {
            try await client.auth.signOut()
        } catch {
            throw AuthenticationError.unknown(error)
        }
    }
    
    func getCurrentUser() async throws -> String? {
        return client.auth.currentUser?.email
    }
    
    func signUp(email: String, password: String) async throws {
        do {
            _ = try await client.auth.signUp(
                email: email,
                password: password
            )
        } catch let error as AuthError {
            let errorMessage = error.localizedDescription.lowercased()
            if errorMessage.contains("user already registered") || errorMessage.contains("user already exists") || errorMessage.contains("already registered") {
                throw AuthenticationError.wrongCredentials
            } else if errorMessage.contains("invalid email") {
                throw AuthenticationError.invalidEmailFormat
            } else {
                throw AuthenticationError.unknown(error)
            }
        } catch {
            throw AuthenticationError.unknown(error)
        }
    }

    func sendPasswordReset(email: String) async throws {
        do {
            try await client.auth.resetPasswordForEmail(email, redirectTo: URL(string: "pagosapp://reset-password"))
        } catch {
            throw AuthenticationError.unknown(error)
        }
    }

    func setSession(accessToken: String, refreshToken: String) async throws {
        do {
            _ = try await client.auth.setSession(accessToken: accessToken, refreshToken: refreshToken)
        } catch {
            throw AuthenticationError.unknown(error)
        }
    }

    func updatePassword(newPassword: String) async throws {
        do {
            try await client.auth.update(user: .init(password: newPassword))
        } catch {
            throw AuthenticationError.unknown(error)
        }
    }
}
