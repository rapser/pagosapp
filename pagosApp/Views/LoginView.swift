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
                }
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)
                
                if isBiometricLoginEnabled && !showEmailPasswordLogin {
                    Button(action: { Task { await onBiometricLogin() } }) {
                        Label("Iniciar con Face ID", systemImage: "faceid")
                    }
                    .padding(.top)
                    
                    Button(action: { showEmailPasswordLogin = true }) {
                        Text("Iniciar con Correo")
                    }
                    .padding(.top)
                } else {
                    TextField("Correo electrónico", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled() // Added this line
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    
                    SecureField("Contraseña", text: $password)
                        .textContentType(.newPassword) // Changed to newPassword for registration
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button(action: { 
                        Task { errorMessage = await onLogin(email, password)?.localizedDescription }
                    }) {
                        Text("Iniciar Sesión")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    // Added Registration Link
                    NavigationLink(destination: RegistrationView()) {
                        Text("¿No tienes cuenta? Regístrate aquí")
                            .font(.callout)
                            .padding(.top)
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