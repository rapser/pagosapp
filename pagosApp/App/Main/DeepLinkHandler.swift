import SwiftUI

/// Handles deep link navigation - primarily password reset flows
struct DeepLinkHandler: ViewModifier {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(AlertManager.self) private var alertManager

    @State private var showResetPassword = false
    @State private var resetToken: String?

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showResetPassword) {
                if let token = resetToken {
                    ResetPasswordView(
                        token: token,
                        viewModel: dependencies.authDependencyContainer.makeResetPasswordViewModel()
                    )
                    .environment(alertManager)
                }
            }
            .onOpenURL { url in
                if url.scheme == "pagosapp" && url.host == "reset-password" {
                    if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                       let queryItems = components.queryItems,
                       let accessToken = queryItems.first(where: { $0.name == "access_token" })?.value {
                        resetToken = accessToken
                        showResetPassword = true
                    }
                }
            }
    }
}

extension View {
    func handleDeepLinks() -> some View {
        modifier(DeepLinkHandler())
    }
}
