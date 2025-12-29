//
//  ResetPasswordView.swift
//  pagosApp
//
//  Created by miguel tomairo on 1/12/25.
//

import SwiftUI
import Supabase

struct ResetPasswordView: View {
    @Bindable var viewModel: ResetPasswordViewModel
    @State private var showSuccessAlert: Bool = false
    @Environment(\.dismiss) var dismiss

    let token: String

    init(token: String, viewModel: ResetPasswordViewModel) {
        self.token = token
        self.viewModel = viewModel
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
                    .disabled(viewModel.isLoading)

                SecureField("Confirmar Contraseña", text: $viewModel.confirmPassword)
                    .padding()
                    .background(Color("AppBackground"))
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                    .disabled(viewModel.isLoading)

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
                    Task {
                        await viewModel.resetPassword(token: token)
                    }
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
                showSuccessAlert = true
            }
        }
        .alert("¡Contraseña Actualizada!", isPresented: $showSuccessAlert) {
            Button("Ir al Login", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Tu contraseña ha sido restablecida exitosamente. Ahora puedes iniciar sesión con tu nueva contraseña.")
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

