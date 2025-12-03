//
//  ResetPasswordView.swift
//  pagosApp
//
//  Created by miguel tomairo on 1/12/25.
//

import SwiftUI
import Supabase

struct ResetPasswordView: View {

    @StateObject private var viewModel: ResetPasswordViewModel
    @EnvironmentObject private var alertManager: AlertManager
    @Environment(\.dismiss) var dismiss

    let accessToken: String
    let refreshToken: String

    init(accessToken: String, refreshToken: String, passwordRecoveryUseCase: PasswordRecoveryUseCase) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        _viewModel = StateObject(wrappedValue: ResetPasswordViewModel(passwordRecoveryUseCase: passwordRecoveryUseCase))
    }

    private var passwordsMatch: Bool {
        !viewModel.newPassword.isEmpty && viewModel.newPassword == viewModel.confirmPassword
    }

    var body: some View {
        ZStack {
            Color("AppBackground").edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {

                Text("Restablecer Contraseña")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AppTextPrimary"))

                Text("Ingresa tu nueva contraseña.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color("AppTextSecondary"))
                    .padding(.horizontal)

                SecureField("Nueva Contraseña", text: $viewModel.newPassword)
                    .padding()
                    .background(Color("AppBackground"))
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)

                SecureField("Confirmar Contraseña", text: $viewModel.confirmPassword)
                    .padding()
                    .background(Color("AppBackground"))
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)

                if !passwordsMatch && !viewModel.confirmPassword.isEmpty {
                    Text("Las contraseñas no coinciden")
                        .foregroundColor(.red)
                        .font(.caption)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(action: {
                    viewModel.resetPassword(accessToken: accessToken, refreshToken: refreshToken)
                }) {
                    Text("Restablecer Contraseña")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("AppPrimary"))
                        .cornerRadius(10)
                        .shadow(color: Color("AppPrimary").opacity(0.5), radius: 10, x: 0, y: 5)
                }
                .disabled(viewModel.isLoading || !passwordsMatch)

                Spacer()
            }
            .padding()

            if viewModel.isLoading {
                LoadingView()
            }
        }
        .onChange(of: viewModel.didResetPassword) { oldValue, newValue in
            if newValue {
                alertManager.show(
                    title: Text("¡Contraseña Actualizada!"),
                    message: Text("Tu contraseña ha sido restablecida exitosamente. Ahora puedes iniciar sesión con tu nueva contraseña."),
                    buttons: [
                        .init(title: Text("Ir al Login"), role: .cancel, action: { dismiss() })
                    ]
                )
            }
        }
    }
}

