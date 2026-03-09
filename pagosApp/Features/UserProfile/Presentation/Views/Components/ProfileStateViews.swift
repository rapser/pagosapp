//
//  ProfileLoadingView.swift
//  pagosApp
//
//  Created on 7/12/25.
//

import SwiftUI

struct ProfileLoadingView: View {
    var body: some View {
        LoadingStateView(style: .inline, message: L10n.Profile.loading)
    }
}

struct ProfileErrorView: View {
    let errorMessage: String
    let onRetry: () -> Void

    var body: some View {
        ErrorStateView(
            title: L10n.Profile.errorTitle,
            message: errorMessage,
            onRetry: onRetry
        )
    }
}
