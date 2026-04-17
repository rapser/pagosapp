//
//  ErrorStateView.swift
//  pagosApp
//
//  Reusable error state: icon, title, message, optional retry button
//

import SwiftUI

struct ErrorStateView: View {
    var title: String = L10n.General.error
    var message: String?
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text(title)
                .font(.headline)
                .foregroundColor(Color("AppTextPrimary"))

            if let message = message, !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if let onRetry = onRetry {
                Button {
                    onRetry()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text(L10n.General.retry)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color("AppPrimary"))
                    .cornerRadius(10)
                }
            }
        }
    }
}
