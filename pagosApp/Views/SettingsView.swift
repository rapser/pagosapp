import SwiftUI
import Combine

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var alertManager: AlertManager
    @StateObject private var settingsManager = SettingsManager.shared

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Seguridad")) {
                    Toggle("Proteger con Face ID / Touch ID", isOn: $settingsManager.isBiometricLockEnabled)
                }
                
                Section(header: Text("Acerca de")) {
                    HStack {
                        Text("Versión")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    Button("Cerrar Sesión", role: .destructive) {
                        showLogoutAlert()
                    }
                }
            }
            .navigationTitle("Ajustes")
        }
    }
    
    private func showLogoutAlert() {
        alertManager.show(
            title: Text("Cerrar Sesión"),
            message: Text("¿Estás seguro de que quieres cerrar la sesión?"),
            buttons: [
                AlertButton(title: Text("Aceptar"), role: .destructive) {
                    Task { await authManager.logout() }
                },
                AlertButton(title: Text("Cancelar"), role: .cancel) { }
            ]
        )
    }
}

#Preview {
    // Dummy AuthenticationService for preview
    class MockAuthService: AuthenticationService {
        func signUp(email: String, password: String) async throws {
            
        }
        
        var isAuthenticatedPublisher: AnyPublisher<Bool, Never> { Just(true).eraseToAnyPublisher() }
        var isAuthenticated: Bool = true
        func signIn(email: String, password: String) async throws { }
        func signOut() async throws { }
        func getCurrentUser() async throws -> String? { return "preview@example.com" }
    }

    return SettingsView()
        .environmentObject(AuthenticationManager(authService: MockAuthService()))
        .environmentObject(AlertManager())
}
