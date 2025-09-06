import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var showEmailPasswordLogin: Bool = false
    
    var onLogin: (String, String) async -> AuthenticationError?
    var onBiometricLogin: () async -> Void
    
    var isBiometricLoginEnabled: Bool
    
    var body: some View {
        NavigationView { // Added NavigationView for navigation
            VStack(spacing: 20) {
                Spacer()
                
                if !isBiometricLoginEnabled || showEmailPasswordLogin {
                    Text("Bienvenido")
                        .font(.largeTitle).bold()
                        .foregroundColor(Color("AppTextPrimary")) // Themed color
                }
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color("AppTextSecondary")) // Themed color
                
                if isBiometricLoginEnabled && !showEmailPasswordLogin {
                    Button(action: { Task { await onBiometricLogin() } }) {
                        Label("Iniciar con Face ID", systemImage: "faceid")
                            .foregroundColor(Color("AppPrimary")) // Themed color
                    }
                    .padding(.top)
                    
                    Button(action: { showEmailPasswordLogin = true }) {
                        Text("Iniciar con Correo")
                            .foregroundColor(Color("AppTextSecondary")) // Themed color
                    }
                    .padding(.top)
                } else {
                    TextField("Correo electrónico", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color("AppBackground")) // Themed color
                        .cornerRadius(10)
                    
                    SecureField("Contraseña", text: $password)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color("AppBackground")) // Themed color
                        .cornerRadius(10)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red) // Keeping red for error messages
                            .font(.caption)
                    }
                    
                    Button(action: { 
                        Task { errorMessage = await onLogin(email, password)?.localizedDescription }
                    }) {
                        Text("Iniciar Sesión")
                            .font(.headline)
                            .foregroundColor(.white) // Keeping white for text on primary button
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("AppPrimary")) // Themed color
                            .cornerRadius(10)
                    }
                    
                    // Added Registration Link
                    NavigationLink(destination: RegistrationView()) {
                        Text("¿No tienes cuenta? Regístrate aquí")
                            .font(.callout)
                            .padding(.top)
                            .foregroundColor(Color("AppPrimary")) // Themed color
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