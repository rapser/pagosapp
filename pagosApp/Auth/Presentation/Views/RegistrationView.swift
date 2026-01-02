import SwiftUI

struct RegistrationView: View {
    @State private var viewModel: RegisterViewModel
    @Environment(\.dismiss) var dismiss

    init(registerViewModel: RegisterViewModel) {
        _viewModel = State(wrappedValue: registerViewModel)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                Text("Crear Cuenta")
                    .font(.largeTitle).bold()
                    .foregroundColor(Color("AppTextPrimary"))

                TextField("Correo electrónico", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color("AppBackground"))
                    .cornerRadius(10)
                    .disabled(viewModel.isLoading)

                HStack {
                    if viewModel.showPassword {
                        TextField("Contraseña", text: $viewModel.password)
                            .textContentType(.newPassword)
                    } else {
                        SecureField("Contraseña", text: $viewModel.password)
                            .textContentType(.newPassword)
                    }

                    Button(action: {
                        viewModel.showPassword.toggle()
                    }) {
                        Image(systemName: viewModel.showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(Color("AppTextSecondary"))
                    }
                }
                .padding()
                .background(Color("AppBackground"))
                .cornerRadius(10)
                .disabled(viewModel.isLoading)

                HStack {
                    if viewModel.showConfirmPassword {
                        TextField("Confirmar Contraseña", text: $viewModel.confirmPassword)
                            .textContentType(.newPassword)
                    } else {
                        SecureField("Confirmar Contraseña", text: $viewModel.confirmPassword)
                            .textContentType(.newPassword)
                    }

                    Button(action: {
                        viewModel.showConfirmPassword.toggle()
                    }) {
                        Image(systemName: viewModel.showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(Color("AppTextSecondary"))
                    }
                }
                .padding()
                .background(Color("AppBackground"))
                .cornerRadius(10)
                .disabled(viewModel.isLoading)

                // Password validation hints
                if !viewModel.password.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: viewModel.isPasswordStrong ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(viewModel.isPasswordStrong ? .green : .red)
                        Text("Mínimo 6 caracteres")
                            .font(.caption)
                            .foregroundColor(Color("AppTextSecondary"))
                    }
                }

                if !viewModel.confirmPassword.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: viewModel.passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(viewModel.passwordsMatch ? .green : .red)
                        Text("Las contraseñas coinciden")
                            .font(.caption)
                            .foregroundColor(Color("AppTextSecondary"))
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(action: {
                    Task {
                        await viewModel.register()
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(viewModel.isLoading ? "Registrando..." : "Registrarse")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isFormValid ? Color("AppSuccess") : Color("AppSuccess").opacity(0.5))
                    .cornerRadius(10)
                }
                .disabled(viewModel.isLoading || !viewModel.isFormValid)

                Spacer()
            }
            .padding()
            .overlay {
                if viewModel.isLoading {
                    Color.black.opacity(0.1)
                        .ignoresSafeArea()
                        .allowsHitTesting(true)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                // Set callback to dismiss on success
                viewModel.onRegistrationSuccess = { _ in
                    dismiss()
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
}

#Preview {
    let dependencies = AppDependencies.mock()
    RegistrationView(registerViewModel: dependencies.authDependencyContainer.makeRegisterViewModel())
}
