//
//  ForgotPasswordView.swift
//  pagosApp
//
//  Created by miguel tomairo on 1/12/25.
//

import SwiftUI

struct ForgotPasswordView: View {
    @State private var viewModel: ForgotPasswordViewModel
    @State private var showSuccessAlert: Bool = false
    @Environment(\.dismiss) var dismiss

    init(passwordRecoveryUseCase: PasswordRecoveryUseCase) {
        _viewModel = State(wrappedValue: ForgotPasswordViewModel(passwordRecoveryUseCase: passwordRecoveryUseCase))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                Text("Restablecer Contraseña")
                    .font(.largeTitle).bold()
                    .foregroundColor(Color("AppTextPrimary"))
                
                Text("Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color("AppTextSecondary"))
                    .padding(.horizontal)
                
                TextField("Correo electrónico", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
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
                        await viewModel.sendPasswordReset()
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(viewModel.isLoading ? "Enviando..." : "Enviar Enlace")
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
            .navigationTitle("¿Olvidaste tu contraseña?")
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
        }
        .onChange(of: viewModel.didSendResetLink) { oldValue, newValue in
            if newValue {
                showSuccessAlert = true
            }
        }
        .alert("Correo Enviado", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Se ha enviado un correo para restablecer tu contraseña. Revisa tu bandeja de entrada.")
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
