import SwiftUI
import Supabase

struct RegistrationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AuthenticationManager.self) private var authManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                Text("Crear Cuenta")
                    .font(.largeTitle).bold()
                    .foregroundColor(Color("AppTextPrimary"))
                
                TextField("Correo electrónico", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color("AppBackground"))
                    .cornerRadius(10)
                    .disabled(isLoading)
                
                SecureField("Contraseña", text: $password)
                    .textContentType(.newPassword)
                    .padding()
                    .background(Color("AppBackground"))
                    .cornerRadius(10)
                    .disabled(isLoading)
                
                SecureField("Confirmar Contraseña", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .padding()
                    .background(Color("AppBackground"))
                    .cornerRadius(10)
                    .disabled(isLoading)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red) // Keeping red for error messages
                        .font(.caption)
                }
                
                Button(action: {
                    Task {
                        isLoading = true
                        if password != confirmPassword {
                            errorMessage = "Las contraseñas no coinciden."
                            isLoading = false
                            return
                        }
                        errorMessage = await authManager.register(email: email, password: password)?.localizedDescription
                        isLoading = false
                        if errorMessage == nil {
                            dismiss()
                        }
                    }
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isLoading ? "Registrando..." : "Registrarse")
                    }
                    .font(.headline)
                    .foregroundColor(.white) // Keeping white for text on primary button
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("AppSuccess"))
                    .cornerRadius(10)
                }
                .disabled(isLoading)
                
                Spacer()
            }
            .padding()
            .overlay {
                if isLoading {
                    Color.black.opacity(0.1)
                        .ignoresSafeArea()
                        .allowsHitTesting(true)
                }
            }
            .navigationTitle("") // Hide default navigation title
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://example.com")!,
        supabaseKey: "dummy_key"
    )
    let adapter = SupabaseAuthAdapter(client: client)
    let repository = AuthRepository(authService: adapter)
    let authManager = AuthenticationManager(authRepository: repository)
    
    RegistrationView()
        .environment(authManager)
}
