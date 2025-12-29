//
//  ProfileLoadingView.swift
//  pagosApp
//
//  Created on 7/12/25.
//

import SwiftUI

struct ProfileLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Cargando perfil...")
                .font(.subheadline)
                .foregroundColor(Color("AppTextSecondary"))
        }
    }
}

struct ProfileErrorView: View {
    let errorMessage: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Error al cargar perfil")
                .font(.headline)
                .foregroundColor(Color("AppTextPrimary"))
            
            Text(errorMessage)
                .font(.subheadline)
                .foregroundColor(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                onRetry()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Reintentar")
                }
                .foregroundColor(.white)
                .padding()
                .background(Color("AppPrimary"))
                .cornerRadius(10)
            }
        }
    }
}
