import SwiftUI
import OSLog

/// Listens for UserDidLogin notification and fetches user profile
struct UserProfileLoader: ViewModifier {
    @Environment(AppDependencies.self) private var dependencies

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "UserProfileLoader")

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogin"))) { notification in
                // Fetch user profile when user logs in (respects Clean Architecture - no direct coupling)
                Task {
                    // Extract userId from notification
                    guard let userInfo = notification.userInfo,
                          let userId = userInfo["userId"] as? UUID else {
                        logger.warning("⚠️ UserDidLogin notification received but no userId found")
                        return
                    }

                    logger.info("📥 Fetching user profile for userId: \(userId.uuidString)")
                    let fetchProfileUseCase = dependencies.userProfileDependencyContainer.makeFetchUserProfileUseCase()
                    let result = await fetchProfileUseCase.execute(userId: userId)

                    if case .success = result {
                        logger.info("✅ User profile fetched and saved during login")
                    } else {
                        logger.error("❌ Failed to fetch user profile during login")
                    }
                }
            }
    }
}

extension View {
    func loadUserProfileOnLogin() -> some View {
        modifier(UserProfileLoader())
    }
}
