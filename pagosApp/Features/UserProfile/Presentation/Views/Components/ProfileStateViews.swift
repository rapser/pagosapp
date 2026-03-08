//
//  ProfileLoadingView.swift
//  pagosApp
//
//  Created on 7/12/25.
//

import SwiftUI

struct ProfileLoadingView: View {
    var body: some View {
        LoadingStateView(style: .inline, message: "Cargando perfil...")
    }
}

struct ProfileErrorView: View {
    let errorMessage: String
    let onRetry: () -> Void

    var body: some View {
        ErrorStateView(
            title: "Error al cargar perfil",
            message: errorMessage,
            onRetry: onRetry
        )
    }
}
