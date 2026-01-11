import SwiftUI

struct LoginView: View {
    @State private var viewModel: LoginViewModel
    @State private var showEmailPasswordLogin: Bool = false
    @Environment(\.dismiss) var dismiss
    @Environment(\.dependencies) private var dependencies

    var onLoginSuccess: ((AuthSession) -> Void)?

    init(loginViewModel: LoginViewModel, onLoginSuccess: ((AuthSession) -> Void)? = nil) {
        _viewModel = State(wrappedValue: loginViewModel)
        self.onLoginSuccess = onLoginSuccess
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                Text("Bienvenido")
                    .font(.largeTitle).bold()
                    .foregroundColor(Color("AppTextPrimary"))

                if viewModel.canUseBiometric && !showEmailPasswordLogin {
                    BiometricLoginSection(
                        biometricIcon: biometricIcon,
                        biometricName: biometricName,
                        isLoading: viewModel.isLoading,
                        onBiometricLogin: {
                            Task {
                                await viewModel.loginWithBiometric()
                            }
                        }
                    )
                } else {
                    EmailPasswordLoginForm(
                        email: $viewModel.email,
                        password: $viewModel.password,
                        showPassword: $viewModel.showPassword,
                        errorMessage: viewModel.errorMessage,
                        isLoading: viewModel.isLoading,
                        isFormValid: viewModel.isFormValid,
                        canUseBiometric: viewModel.canUseBiometric,
                        biometricName: biometricName,
                        onLogin: {
                            Task {
                                await viewModel.login()
                            }
                        },
                        onSwitchToBiometric: {
                            showEmailPasswordLogin = false
                        },
                        forgotPasswordView: AnyView(
                            NavigationLink(destination: ForgotPasswordView(passwordRecoveryUseCase: viewModel.getPasswordRecoveryUseCase())) {
                                Text("¿Olvidaste tu contraseña?")
                                    .font(.callout)
                                    .padding(.top, 5)
                                    .foregroundColor(Color("AppTextSecondary"))
                            }
                        ),
                        registrationView: AnyView(
                            NavigationLink(
                                destination: RegistrationView(
                                    registerViewModel: dependencies.authDependencyContainer.makeRegisterViewModel()
                                )
                            ) {
                                Text("¿No tienes cuenta? Regístrate aquí")
                                    .font(.callout)
                                    .padding(.top)
                                    .foregroundColor(Color("AppPrimary"))
                            }
                        )
                    )
                }

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
            .onAppear {
                let hasCredentials = viewModel.hasBiometricCredentials()
                showEmailPasswordLogin = !hasCredentials
                viewModel.onLoginSuccess = onLoginSuccess
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

    // MARK: - Computed Properties

    private var biometricIcon: String {
        switch viewModel.biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "faceid"
        }
    }

    private var biometricName: String {
        viewModel.biometricType.description
    }
}

#Preview {
    let dependencies = AppDependencies.mock()
    LoginView(loginViewModel: dependencies.authDependencyContainer.makeLoginViewModel())
}
