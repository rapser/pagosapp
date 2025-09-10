import SwiftUI
import Supabase

struct RegistrationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    
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
                        print("RegistrationView: Register button tapped.")
                        print("RegistrationView: Email: \(email), Password: \(password), Confirm: \(confirmPassword)")
                        if password != confirmPassword {
                            errorMessage = "Las contraseñas no coinciden."
                            print("RegistrationView: Passwords do not match.")
                            return
                        }
                        errorMessage = await authManager.register(email: email, password: password)?.localizedDescription
                        if errorMessage == nil {
                            print("RegistrationView: Registration successful. Dismissing view.")
                            dismiss()
                        } else {
                            print("RegistrationView: Registration failed with error: \(errorMessage ?? "Unknown")")
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
    RegistrationView()
        .environmentObject(AuthenticationManager(authService: SupabaseAuthService(client: SupabaseClient(supabaseURL: URL(string: "https://example.com")!, supabaseKey: "dummy_key"))))
}
