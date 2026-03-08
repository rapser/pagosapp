import SwiftUI
import LocalAuthentication

struct BiometricSettingsView: View {
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(SessionCoordinator.self) private var sessionCoordinator
    
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

                    Text(L10n.Settings.Biometric.fastAccess)
                        .font(.title2)
                        .bold()
                        .foregroundColor(Color("AppTextPrimary"))

                    Text(L10n.Settings.Biometric.description)
                        .font(.body)
                        .foregroundColor(Color("AppTextSecondary"))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(L10n.Settings.Biometric.benefits)
                        .font(.headline)
                        .foregroundColor(Color("AppTextPrimary"))
                        .padding(.top, 8)

                    BenefitRow(icon: "lock.fill", text: L10n.Settings.Biometric.benefit1)
                    BenefitRow(icon: "bolt.fill", text: L10n.Settings.Biometric.benefit2)
                    BenefitRow(icon: "hand.raised.fill", text: L10n.Settings.Biometric.benefit3)
                }
                .padding(.vertical, 8)
            }

            Section {
                Toggle("Habilitar Face ID / Touch ID", isOn: Binding(
                    get: { settingsStore.isBiometricLockEnabled },
                    set: { newValue in
                        if newValue {
                            // Check if credentials are already stored (user already logged in)
                            if sessionCoordinator.hasBiometricCredentials() {
                                // Credentials exist, just enable without asking for Face ID again
                                settingsStore.isBiometricLockEnabled = true
                            } else {
                                // No credentials stored, this shouldn't happen but handle edge case
                                errorMessage = L10n.Settings.Biometric.loginRequired
                                showError = true
                            }
                        } else {
                            settingsStore.isBiometricLockEnabled = false
                            Task {
                                await sessionCoordinator.clearBiometricCredentials()
                            }
                        }
                    }
                ))
                    .tint(Color("AppPrimary"))
                    .disabled(!sessionCoordinator.canUseBiometrics)

                if !sessionCoordinator.canUseBiometrics {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(L10n.Settings.Biometric.notAvailable)
                            .font(.caption)
                            .foregroundColor(Color("AppTextSecondary"))
                    }
                }
            } header: {
                Text(L10n.Settings.Biometric.configuration)
                    .foregroundColor(Color("AppTextPrimary"))
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(Color("AppPrimary"))
                        Text(L10n.Settings.Biometric.important)
                            .font(.headline)
                            .foregroundColor(Color("AppTextPrimary"))
                    }

                    Text(L10n.Settings.Biometric.importantMessage)
                        .font(.caption)
                        .foregroundColor(Color("AppTextSecondary"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(L10n.Settings.Biometric.title)
        .navigationBarTitleDisplayMode(.inline)
        .errorAlert(isPresented: $showError, message: errorMessage.isEmpty ? nil : errorMessage)
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
            .environment(dependencies.sessionCoordinator)
    }
}
