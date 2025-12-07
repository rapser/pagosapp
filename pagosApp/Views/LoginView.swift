import SwiftUI

struct LoginView: View {
    @Environment(PasswordRecoveryUseCase.self) private var passwordRecoveryUseCase
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var showEmailPasswordLogin: Bool = false
    @State private var isLoading = false

    var onLogin: (String, String) async -> AuthenticationError?
    var onBiometricLogin: () async -> Void

    var isBiometricLoginEnabled: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()

                Text("Bienvenido")
                    .font(.largeTitle).bold()
                    .foregroundColor(Color("AppTextPrimary"))

                if isBiometricLoginEnabled && !showEmailPasswordLogin {
                    Image(systemName: "faceid")
                        .font(.system(size: 80))
                        .foregroundColor(Color("AppPrimary"))

                    Text("Usa Face ID para acceder")
                        .font(.headline)
                        .foregroundColor(Color("AppTextPrimary"))
                        .padding(.top, 8)

                    Button(action: { 
                        Task { 
                            await onBiometricLogin()
                        }
                    }) {
                        HStack {
                            Image(systemName: "faceid")
                            Text("Ingresar con Face ID")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("AppPrimary"))
                        .cornerRadius(10)
                    }
                    .padding(.top, 20)
                } else {
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
                    
                    SecureField("Contraseña", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color("AppBackground"))
                        .cornerRadius(10)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red) // Keeping red for error messages
                            .font(.caption)
                    }
                    
                    Button(action: { 
                        Task { 
                            isLoading = true
                            errorMessage = await onLogin(email, password)?.localizedDescription
                            isLoading = false
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isLoading ? "Iniciando sesión..." : "Iniciar Sesión")
                        }
                        .font(.headline)
                        .foregroundColor(.white) // Keeping white for text on primary button
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("AppPrimary"))
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                    
                    // Added Registration Link
                    NavigationLink(destination: RegistrationView()) {
                        Text("¿No tienes cuenta? Regístrate aquí")
                            .font(.callout)
                            .padding(.top)
                            .foregroundColor(Color("AppPrimary"))
                    }
                    
                    NavigationLink(destination: ForgotPasswordView(passwordRecoveryUseCase: passwordRecoveryUseCase)) {
                        Text("¿Olvidaste tu contraseña?")
                            .font(.callout)
                            .padding(.top, 5)
                            .foregroundColor(Color("AppTextSecondary"))
                    }
                }
                
                Spacer()
            }
            .padding()
            .onAppear {
                // If biometrics are enabled, start with biometric login view
                if isBiometricLoginEnabled {
                    showEmailPasswordLogin = false
                } else {
                    showEmailPasswordLogin = true
                }
            }
        }
    }
}

#Preview {
    LoginView(onLogin: { _,_ in return .wrongCredentials }, onBiometricLogin: { }, isBiometricLoginEnabled: true)
}
