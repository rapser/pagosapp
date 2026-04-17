import SwiftUI

struct BiometricLoginSection: View {
    let biometricIcon: String
    let biometricName: String
    let isLoading: Bool
    let onBiometricLogin: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: biometricIcon)
                .font(.system(size: 80))
                .foregroundColor(Color("AppPrimary"))
                .accessibilityLabel(biometricName)
                .accessibilityHidden(true)  // Decorative, handled by button label

            Text(L10n.Auth.Biometric.useToAccess(biometricName))
                .font(.headline)
                .foregroundColor(Color("AppTextPrimary"))
                .padding(.top, 8)

            Button(action: onBiometricLogin) {
                HStack {
                    Image(systemName: biometricIcon)
                        .accessibilityHidden(true)
                    Text(L10n.Auth.Biometric.signInWith(biometricName))
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("AppPrimary"))
                .cornerRadius(10)
            }
            .padding(.top, 20)
            .disabled(isLoading)
            .accessibilityLabel(L10n.Auth.Biometric.a11ySignIn(biometricName))
            .accessibilityHint(isLoading ? L10n.Auth.Biometric.a11yHintLoading : L10n.Auth.Biometric.a11yHintIdle(biometricName))
        }
    }
}
