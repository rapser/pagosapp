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
        print("SupabaseAuthService: Initial isAuthenticated: \(initialAuthStatus)")
        
        // Check for stale session on app launch
        // If Supabase found a session (initialAuthStatus is true)
        // but our app's internal flag (hasLoggedInWithCredentials) is false,
        // it means a stale session from Keychain. Force logout.
        let hasLoggedInWithCredentialsKey = "hasLoggedInWithCredentials" // Define key locally or pass it
        let hasLoggedInWithCredentials = UserDefaults.standard.bool(forKey: hasLoggedInWithCredentialsKey)
        print("SupabaseAuthService: hasLoggedInWithCredentials (from UserDefaults): \(hasLoggedInWithCredentials)")
        
        if initialAuthStatus && !hasLoggedInWithCredentials {
            print("SupabaseAuthService: Stale session detected in Keychain. Forcing signOut.")
            Task {
                do {
                    try await client.auth.signOut()
                    // Update local state after forced logout
                    self._isAuthenticated.value = false
                    UserDefaults.standard.set(false, forKey: hasLoggedInWithCredentialsKey)
                    print("SupabaseAuthService: Forced signOut successful. isAuthenticated set to false.")
                } catch {
                    print("SupabaseAuthService: Error forcing logout of stale session: \(error.localizedDescription)")
                }
            }
        }

        Task {
            for await state in client.auth.authStateChanges {
                print("SupabaseAuthService: Auth state change event: \(state.event)")
                switch state.event {
                case .signedIn, .signedOut, .tokenRefreshed, .userUpdated, .passwordRecovery:
                    self._isAuthenticated.value = (self.client.auth.currentUser != nil)
                    print("SupabaseAuthService: isAuthenticated updated by authChangeEvent to \(self._isAuthenticated.value)")
                case .initialSession:
                    self._isAuthenticated.value = (self.client.auth.currentUser != nil)
                    print("SupabaseAuthService: isAuthenticated updated by initialSession to \(self._isAuthenticated.value)")
                case .userDeleted:
                    self._isAuthenticated.value = false
                    print("SupabaseAuthService: isAuthenticated updated by userDeleted to \(self._isAuthenticated.value)")
                case .mfaChallengeVerified:
                    self._isAuthenticated.value = (self.client.auth.currentUser != nil)
                    print("SupabaseAuthService: isAuthenticated updated by mfaChallengeVerified to \(self._isAuthenticated.value)")
                }
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        print("SupabaseAuthService: Attempting signIn for \(email)")
        do {
            _ = try await client.auth.signIn(email: email, password: password)
            print("SupabaseAuthService: signIn successful.")
        } catch let error as AuthError {
            print("SupabaseAuthService: signIn failed with AuthError: \(error.localizedDescription)")
            print("SupabaseAuthService: Full AuthError: \(error)")
            if error.message.contains("invalid login credentials") {
                throw AuthenticationError.wrongCredentials
            } else {
                throw AuthenticationError.unknown(error)
            }
        } catch {
            print("SupabaseAuthService: signIn failed with unknown error: \(error.localizedDescription)")
            print("SupabaseAuthService: Full unknown error: \(error)")
            throw AuthenticationError.unknown(error)
        }
    }
    
    func signOut() async throws {
        print("SupabaseAuthService: Attempting signOut.")
        do {
            try await client.auth.signOut()
            print("SupabaseAuthService: signOut successful.")
        } catch {
            print("SupabaseAuthService: signOut failed with error: \(error.localizedDescription)")
            print("SupabaseAuthService: Full signOut error: \(error)")
            throw AuthenticationError.unknown(error)
        }
    }
    
    func getCurrentUser() async throws -> String? {
        return client.auth.currentUser?.email
    }
    
    func signUp(email: String, password: String) async throws {
        print("SupabaseAuthService: Attempting signUp for \(email)")
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password
            )
            let user = response.user
            print("✅ Usuario registrado: \(user.email ?? "sin correo")")
            // session sí puede ser nil (ej: si necesitas confirmar correo)
            if let session = response.session {
                print("🔑 Sesión creada automáticamente. Access token: \(session.accessToken)")
            } else {
                print("ℹ️ Usuario registrado pero requiere verificación de correo antes de iniciar sesión.")
            }
            
        } catch let error as AuthError {
            print("❌ SupabaseAuthService: signUp failed with AuthError: \(error.localizedDescription)")
            print("SupabaseAuthService: Full AuthError: \(error)")
            
            if error.message.contains("User already registered") || error.message.contains("User already exists") {
                throw AuthenticationError.wrongCredentials
            } else if error.message.contains("invalid email") {
                throw AuthenticationError.invalidEmailFormat
            } else {
                throw AuthenticationError.unknown(error)
            }
        } catch {
            print("❌ SupabaseAuthService: signUp failed with unknown error: \(error.localizedDescription)")
            print("SupabaseAuthService: Full unknown error: \(error)")
            throw AuthenticationError.unknown(error)
        }
    }

}
