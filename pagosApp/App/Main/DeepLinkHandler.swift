import SwiftUI
import OSLog

/// Handles deep link navigation - primarily password reset flows
struct DeepLinkHandler: ViewModifier {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(AlertManager.self) private var alertManager

    @State private var showResetPassword = false
    @State private var resetToken: String?

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "DeepLinkHandler")

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
                logger.info("Deep link opened: \(url.absoluteString)")
                if url.scheme == "pagosapp" && url.host == "reset-password" {
                    logger.info("Processing password reset deep link")
                    if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                       let queryItems = components.queryItems {
                        // Extract access_token (used as reset token by Supabase)
                        if let accessToken = queryItems.first(where: { $0.name == "access_token" })?.value {
                            resetToken = accessToken
                            showResetPassword = true
                            logger.info("Password reset token found")
                        } else {
                            logger.error("No access_token found in URL")
                        }
                    } else {
                        logger.error("Failed to parse URL components")
                    }
                } else {
                    logger.info("URL does not match expected scheme/host")
                }
            }
    }
}

extension View {
    func handleDeepLinks() -> some View {
        modifier(DeepLinkHandler())
    }
}
