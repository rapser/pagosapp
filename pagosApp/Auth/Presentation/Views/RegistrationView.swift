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

                SecureTextFieldWithToggle(
                    placeholder: "Contraseña",
                    text: $viewModel.password,
                    isSecure: $viewModel.showPassword,
                    textContentType: .newPassword,
                    isDisabled: viewModel.isLoading
                )

                SecureTextFieldWithToggle(
                    placeholder: "Confirmar Contraseña",
                    text: $viewModel.confirmPassword,
                    isSecure: $viewModel.showConfirmPassword,
                    textContentType: .newPassword,
                    isDisabled: viewModel.isLoading
                )

                // Password validation hints
                if !viewModel.password.isEmpty {
                    ValidationHintRow(
                        isValid: viewModel.isPasswordStrong,
                        message: "Mínimo 6 caracteres"
                    )
                }

                if !viewModel.confirmPassword.isEmpty {
                    ValidationHintRow(
                        isValid: viewModel.passwordsMatch,
                        message: "Las contraseñas coinciden"
                    )
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
                    .background(viewModel.isFormValid ? Color("AppPrimary") : Color("AppPrimary").opacity(0.5))
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
            .navigationTitle("Crear Cuenta")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Atrás")
                        }
                        .foregroundColor(Color("AppTextPrimary"))
                    }
                }
            }
            .onAppear {
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
