//
//  ErrorAlertModifier.swift
//  pagosApp
//
//  Reusable error alert ViewModifier to avoid duplicating .alert("Error", ...) across views
//

import SwiftUI

/// ViewModifier that shows a standard error alert (title "Error", OK button, optional message)
struct ErrorAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    var message: String?
    var title: String = L10n.General.error
    var onDismiss: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $isPresented) {
                Button(L10n.General.ok, role: .cancel) {
                    onDismiss?()
                }
            } message: {
                if let message = message, !message.isEmpty {
                    Text(message)
                }
            }
    }
}

extension View {
    /// Presents a standard error alert when `isPresented` is true
    func errorAlert(
        isPresented: Binding<Bool>,
        message: String?,
        title: String = L10n.General.error,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        modifier(ErrorAlertModifier(isPresented: isPresented, message: message, title: title, onDismiss: onDismiss))
    }
}
