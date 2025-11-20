import Foundation
import Supabase
import Combine

@MainActor
class SupabaseAuthService: @preconcurrency AuthenticationService {
    private let client: SupabaseClient
    private let _isAuthenticated = CurrentValueSubject<Bool, Never>(false)
    
    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> {
        _isAuthenticated.eraseToAnyPublisher()
    }
    
    var isAuthenticated: Bool {
        _isAuthenticated.value
    }
    
    init(client: SupabaseClient) {
        self.client = client
        // Initial check
        let initialAuthStatus = (client.auth.currentUser != nil)
        _isAuthenticated.value = initialAuthStatus

        Task {
            for await state in client.auth.authStateChanges {
                switch state.event {
                case .signedIn, .signedOut, .tokenRefreshed, .userUpdated, .passwordRecovery:
                    self._isAuthenticated.value = (self.client.auth.currentUser != nil)
                case .initialSession:
                    self._isAuthenticated.value = (self.client.auth.currentUser != nil)
                case .userDeleted:
                    self._isAuthenticated.value = false
                case .mfaChallengeVerified:
                    self._isAuthenticated.value = (self.client.auth.currentUser != nil)
                }
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            _ = try await client.auth.signIn(email: email, password: password)
        } catch let error as AuthError {
            if error.message.contains("invalid login credentials") {
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
            if error.message.contains("User already registered") || error.message.contains("User already exists") {
                throw AuthenticationError.wrongCredentials
            } else if error.message.contains("invalid email") {
                throw AuthenticationError.invalidEmailFormat
            } else {
                throw AuthenticationError.unknown(error)
            }
        } catch {
            throw AuthenticationError.unknown(error)
        }
    }

}
