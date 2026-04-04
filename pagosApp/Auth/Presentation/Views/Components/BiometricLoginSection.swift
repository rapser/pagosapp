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

            Text("Usa \(biometricName) para acceder")
                .font(.headline)
                .foregroundColor(Color("AppTextPrimary"))
                .padding(.top, 8)

            Button(action: onBiometricLogin) {
                HStack {
                    Image(systemName: biometricIcon)
                        .accessibilityHidden(true)
                    Text("Ingresar con \(biometricName)")
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
            .accessibilityLabel("Iniciar sesión con \(biometricName)")
            .accessibilityHint(isLoading ? "Autenticando" : "Toca para autenticarte con \(biometricName)")
        }
    }
}
