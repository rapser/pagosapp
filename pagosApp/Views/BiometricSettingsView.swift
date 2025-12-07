import SwiftUI
import Supabase
import LocalAuthentication

struct BiometricSettingsView: View {
    @StateObject private var settingsManager = SettingsManager.shared
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.modelContext) private var modelContext
    
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Spacer()
                        Image(systemName: "faceid")
                            .font(.system(size: 70))
                            .foregroundColor(Color("AppPrimary"))
                        Spacer()
                    }
                    .padding(.vertical)

                    Text("Acceso rápido y seguro")
                        .font(.title2)
                        .bold()
                        .foregroundColor(Color("AppTextPrimary"))

                    Text("Face ID / Touch ID te permite acceder a la aplicación de forma rápida y segura sin necesidad de ingresar tu correo y contraseña cada vez.")
                        .font(.body)
                        .foregroundColor(Color("AppTextSecondary"))
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Beneficios:")
                        .font(.headline)
                        .foregroundColor(Color("AppTextPrimary"))
                        .padding(.top, 8)

                    BenefitRow(icon: "lock.fill", text: "Mayor seguridad con autenticación biométrica")
                    BenefitRow(icon: "bolt.fill", text: "Acceso instantáneo a tus pagos")
                    BenefitRow(icon: "hand.raised.fill", text: "No más contraseñas que recordar")
                }
                .padding(.vertical, 8)
            }

            Section {
                Toggle("Habilitar Face ID / Touch ID", isOn: Binding(
                    get: { settingsManager.isBiometricLockEnabled },
                    set: { newValue in
                        if newValue {
                            // Check if credentials are already stored (user already logged in)
                            if KeychainManager.hasStoredCredentials() {
                                // Credentials exist, just enable without asking for Face ID again
                                settingsManager.isBiometricLockEnabled = true
                            } else {
                                // No credentials stored, this shouldn't happen but handle edge case
                                errorMessage = "Debes iniciar sesión primero para habilitar Face ID"
                                showError = true
                            }
                        } else {
                            // When disabling, delete credentials from Keychain
                            settingsManager.isBiometricLockEnabled = false
                            Task {
                                await authManager.clearBiometricCredentials(modelContext: modelContext)
                            }
                        }
                    }
                ))
                    .tint(Color("AppPrimary"))
                    .disabled(!authManager.canUseBiometrics)

                if !authManager.canUseBiometrics {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Face ID / Touch ID no está disponible en este dispositivo")
                            .font(.caption)
                            .foregroundColor(Color("AppTextSecondary"))
                    }
                }
            } header: {
                Text("Configuración")
                    .foregroundColor(Color("AppTextPrimary"))
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(Color("AppPrimary"))
                        Text("Importante")
                            .font(.headline)
                            .foregroundColor(Color("AppTextPrimary"))
                    }

                    Text("Al activar esta opción, la próxima vez que abras la aplicación solo necesitarás usar Face ID para acceder. Tu información permanece segura y protegida.")
                        .font(.caption)
                        .foregroundColor(Color("AppTextSecondary"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Autenticación Biométrica")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color("AppPrimary"))
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundColor(Color("AppTextSecondary"))
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationView {
        BiometricSettingsView()
            .environmentObject(AuthenticationManager(authService: SupabaseAuthService(client: SupabaseClient(supabaseURL: URL(string: "https://example.com") ?? URL(filePath: "/"), supabaseKey: "dummy_key"))))
    }
}
