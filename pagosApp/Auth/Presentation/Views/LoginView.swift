import SwiftUI

struct LoginView: View {
    @State private var viewModel: LoginViewModel
    @State private var showEmailPasswordLogin: Bool = false
    @Environment(\.dismiss) var dismiss

    var onLoginSuccess: ((AuthSession) -> Void)?

    init(loginViewModel: LoginViewModel) {
        _viewModel = State(wrappedValue: loginViewModel)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                Text("Bienvenido")
                    .font(.largeTitle).bold()
                    .foregroundColor(Color("AppTextPrimary"))

                if viewModel.canUseBiometric && !showEmailPasswordLogin {
                    Image(systemName: biometricIcon)
                        .font(.system(size: 80))
                        .foregroundColor(Color("AppPrimary"))

                    Text("Usa \(biometricName) para acceder")
                        .font(.headline)
                        .foregroundColor(Color("AppTextPrimary"))
                        .padding(.top, 8)

                    Button(action: {
                        Task {
                            await viewModel.loginWithBiometric()
                        }
                    }) {
                        HStack {
                            Image(systemName: biometricIcon)
                            Text("Ingresar con \(biometricName)")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("AppPrimary"))
                        .cornerRadius(10)
                    }
                    .padding(.top, 20)
                    .disabled(viewModel.isLoading)
                } else {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color("AppTextSecondary"))

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
                                .textContentType(.password)
                        } else {
                            SecureField("Contraseña", text: $viewModel.password)
                                .textContentType(.password)
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

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    Button(action: {
                        Task {
                            await viewModel.login()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(viewModel.isLoading ? "Iniciando sesión..." : "Iniciar Sesión")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isFormValid ? Color("AppPrimary") : Color("AppPrimary").opacity(0.5))
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isLoading || !viewModel.isFormValid)

                    // Registration Link
                    // TODO: Get RegisterViewModel from DI Container
                    NavigationLink(destination: Text("Registro temporalmente deshabilitado")) {
                        Text("¿No tienes cuenta? Regístrate aquí")
                            .font(.callout)
                            .padding(.top)
                            .foregroundColor(Color("AppPrimary"))
                    }
                    .disabled(viewModel.isLoading)

                    NavigationLink(destination: ForgotPasswordView(passwordRecoveryUseCase: viewModel.getPasswordRecoveryUseCase())) {
                        Text("¿Olvidaste tu contraseña?")
                            .font(.callout)
                            .padding(.top, 5)
                            .foregroundColor(Color("AppTextSecondary"))
                    }
                    .disabled(viewModel.isLoading)

                    if viewModel.canUseBiometric {
                        Button(action: {
                            showEmailPasswordLogin = false
                        }) {
                            Text("Usar \(biometricName)")
                                .font(.callout)
                                .padding(.top, 5)
                                .foregroundColor(Color("AppTextSecondary"))
                        }
                        .disabled(viewModel.isLoading)
                    }
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
                Task {
                    // Check biometric availability
                    let canUse = await viewModel.canUseBiometricLogin()
                    let biometricType = await viewModel.getBiometricType()

                    // If biometrics are enabled, start with biometric login view
                    if canUse && biometricType != .none {
                        showEmailPasswordLogin = false
                    } else {
                        showEmailPasswordLogin = true
                    }
                }

                // Set callback
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
    let authContainer = AuthDependencyContainer(supabaseClient: dependencies.supabaseClient)

    LoginView(loginViewModel: authContainer.makeLoginViewModel())
}
