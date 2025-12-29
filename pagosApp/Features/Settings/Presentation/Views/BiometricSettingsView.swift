import SwiftUI
import LocalAuthentication

struct BiometricSettingsView: View {
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(AuthenticationManager.self) private var authManager
    
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
                    get: { settingsStore.isBiometricLockEnabled },
                    set: { newValue in
                        if newValue {
                            // Check if credentials are already stored (user already logged in)
                            if KeychainManager.hasStoredCredentials() {
                                // Credentials exist, just enable without asking for Face ID again
                                settingsStore.isBiometricLockEnabled = true
                            } else {
                                // No credentials stored, this shouldn't happen but handle edge case
                                errorMessage = "Debes iniciar sesión primero para habilitar Face ID"
                                showError = true
                            }
                        } else {
                            settingsStore.isBiometricLockEnabled = false
                            Task {
                                await authManager.clearBiometricCredentials()
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
    let dependencies = AppDependencies.mock()

    NavigationStack {
        BiometricSettingsView()
            .environment(dependencies.authenticationManager)
    }
}
