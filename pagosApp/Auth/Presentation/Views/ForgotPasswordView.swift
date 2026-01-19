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
        ZStack {
            Color("AppBackground").edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                
                Text("Restablecer Contraseña")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AppTextPrimary"))
                
                Text("Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color("AppTextSecondary"))
                    .padding(.horizontal)
                
                TextField("Correo Electrónico", text: $viewModel.email)
                    .padding()
                    .background(Color("AppBackground"))
                    .cornerRadius(10)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                    .disabled(viewModel.isLoading)
                
                Button(action: {
                    Task {
                        await viewModel.sendPasswordReset()
                    }
                }) {
                    Text("Enviar Enlace")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("AppPrimary"))
                        .cornerRadius(10)
                        .shadow(color: Color("AppPrimary").opacity(0.5), radius: 10, x: 0, y: 5)
                }
                .disabled(viewModel.isLoading)
                
                Spacer()
            }
            .padding()
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
            
            if viewModel.isLoading {
                LoadingView()
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
