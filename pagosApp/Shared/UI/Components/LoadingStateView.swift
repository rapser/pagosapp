//
//  LoadingStateView.swift
//  pagosApp
//
//  Unified loading indicator: overlay (full-screen card) or inline (spinner + message)
//

import SwiftUI

enum LoadingStateStyle {
    case overlay
    case inline
}

struct LoadingStateView: View {
    var style: LoadingStateStyle = .inline
    var message: String?

    var body: some View {
        switch style {
        case .overlay:
            overlayContent
        case .inline:
            inlineContent
        }
    }

    private var overlayContent: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("AppPrimary")))
                    .scaleEffect(1.5)
                if let message = message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(Color("AppTextPrimary"))
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("AppBackground"))
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
        }
    }

    private var inlineContent: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                if let message = message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(Color("AppTextSecondary"))
                }
            }
            Spacer()
        }
    }
}
