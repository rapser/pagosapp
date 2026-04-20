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

                Text(L10n.Auth.Register.title)
                    .font(.largeTitle).bold()
                    .foregroundColor(Color("AppTextPrimary"))

                TextField(L10n.Auth.Field.email, text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color("AppBackground"))
                    .cornerRadius(10)
                    .disabled(viewModel.isLoading)

                SecureTextFieldWithToggle(
                    placeholder: L10n.Auth.Field.password,
                    text: $viewModel.password,
                    isSecure: $viewModel.showPassword,
                    textContentType: .newPassword,
                    isDisabled: viewModel.isLoading
                )

                SecureTextFieldWithToggle(
                    placeholder: L10n.Auth.Field.confirmPassword,
                    text: $viewModel.confirmPassword,
                    isSecure: $viewModel.showConfirmPassword,
                    textContentType: .newPassword,
                    isDisabled: viewModel.isLoading
                )

                // Password validation hints
                if !viewModel.password.isEmpty {
                    ValidationHintRow(
                        isValid: viewModel.isPasswordStrong,
                        message: L10n.Auth.Register.passwordHintMin
                    )
                }

                if !viewModel.confirmPassword.isEmpty {
                    ValidationHintRow(
                        isValid: viewModel.passwordsMatch,
                        message: L10n.Auth.Register.passwordMatch
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
                }, label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(viewModel.isLoading ? L10n.Auth.Register.signingUp : L10n.Auth.Register.signUp)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isFormValid ? Color("AppPrimary") : Color("AppPrimary").opacity(0.5))
                    .cornerRadius(10)
                })
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
            .navigationTitle(L10n.Auth.Register.title)
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
                            Text(L10n.Auth.Register.back)
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
            .errorAlert(isPresented: $viewModel.showError, message: viewModel.errorMessage)
        }
    }
}

#Preview {
    let dependencies = AppDependencies.mock()
    RegistrationView(registerViewModel: dependencies.authDependencyContainer.makeRegisterViewModel())
}
