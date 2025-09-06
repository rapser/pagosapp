import SwiftUI

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
                    authManager.logout()
                },
                AlertButton(title: Text("Cancelar"), role: .cancel) { }
            ]
        )
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthenticationManager())
        .environmentObject(AlertManager())
}