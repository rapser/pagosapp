import SwiftUI

struct EmailPasswordLoginForm: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var showPassword: Bool
    let errorMessage: String?
    let isLoading: Bool
    let isFormValid: Bool
    let canUseBiometric: Bool
    let biometricName: String
    let onLogin: () -> Void
    let onSwitchToBiometric: () -> Void
    let forgotPasswordView: AnyView
    let registrationView: AnyView

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(Color("AppTextSecondary"))

            TextField("Correo electrónico", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .padding()
                .background(Color("AppBackground"))
                .cornerRadius(10)
                .disabled(isLoading)

            SecureTextFieldWithToggle(
                placeholder: "Contraseña",
                text: $password,
                isSecure: $showPassword,
                textContentType: .password,
                isDisabled: isLoading
            )

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button(action: onLogin) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text(isLoading ? "Iniciando sesión..." : "Iniciar Sesión")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color("AppPrimary") : Color("AppPrimary").opacity(0.5))
                .cornerRadius(10)
            }
            .disabled(isLoading || !isFormValid)

            // Registration Link
            registrationView
                .disabled(isLoading)

            forgotPasswordView
                .disabled(isLoading)

            if canUseBiometric {
                Button(action: onSwitchToBiometric) {
                    Text("Usar \(biometricName)")
                        .font(.callout)
                        .padding(.top, 5)
                        .foregroundColor(Color("AppTextSecondary"))
                }
                .disabled(isLoading)
            }
        }
    }
}
