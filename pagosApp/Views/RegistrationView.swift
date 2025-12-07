import SwiftUI
import Supabase

struct RegistrationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AuthenticationManager.self) private var authManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
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
                
                SecureField("Contraseña", text: $password)
                    .textContentType(.newPassword)
                    .padding()
                    .background(Color("AppBackground"))
                    .cornerRadius(10)
                
                SecureField("Confirmar Contraseña", text: $confirmPassword)
                    .textContentType(.newPassword)
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
                        if password != confirmPassword {
                            errorMessage = "Las contraseñas no coinciden."
                            return
                        }
                        errorMessage = await authManager.register(email: email, password: password)?.localizedDescription
                        if errorMessage == nil {
                            dismiss()
                        }
                    }
                }) {
                    Text("Registrarse")
                        .font(.headline)
                        .foregroundColor(.white) // Keeping white for text on primary button
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("AppSuccess"))
                        .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
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
