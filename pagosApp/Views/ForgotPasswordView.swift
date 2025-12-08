//
//  ForgotPasswordView.swift
//  pagosApp
//
//  Created by miguel tomairo on 1/12/25.
//

import SwiftUI
import Supabase

struct ForgotPasswordView: View {

    @State private var viewModel: ForgotPasswordViewModel
    @Environment(AlertManager.self) private var alertManager
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
                    viewModel.sendPasswordReset()
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
            
            if viewModel.isLoading {
                LoadingView()
            }
        }
        .onChange(of: viewModel.didSendResetLink) { oldValue, newValue in
            if newValue {
                alertManager.show(
                    title: Text("Correo Enviado"),
                    message: Text("Se ha enviado un correo para restablecer tu contraseña. Revisa tu bandeja de entrada."),
                    buttons: [
                        .init(title: Text("OK"), role: .cancel, action: { dismiss() })
                    ]
                )
            }
        }
    }
}
