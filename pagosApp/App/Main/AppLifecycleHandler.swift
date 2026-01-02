import SwiftUI

/// Handles app lifecycle events - scenePhase changes and foreground session checks
struct AppLifecycleHandler: ViewModifier {
    @Environment(SessionCoordinator.self) private var sessionCoordinator
    @Environment(\.scenePhase) private var scenePhase

    private let foregroundCheckInterval: TimeInterval = 30
    @State private var foregroundCheckTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onChange(of: sessionCoordinator.isAuthenticated) { oldValue, newValue in
                if newValue {
                    sessionCoordinator.updateLastActiveTimestamp()
                    startForegroundCheckTimer()
                } else if oldValue == true && newValue == false {
                    stopForegroundCheckTimer()
                }
            }
            .onChange(of: scenePhase) { oldValue, newPhase in
                if newPhase == .active {
                    if sessionCoordinator.isAuthenticated {
                        sessionCoordinator.checkSession()
                        startForegroundCheckTimer()
                    }
                } else if newPhase == .background || newPhase == .inactive {
                    if sessionCoordinator.isAuthenticated {
                        sessionCoordinator.updateLastActiveTimestamp()
                    }
                    stopForegroundCheckTimer()
                }
            }
    }

    private func startForegroundCheckTimer() {
        stopForegroundCheckTimer()

        foregroundCheckTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(foregroundCheckInterval))
                if !Task.isCancelled && sessionCoordinator.isAuthenticated {
                    sessionCoordinator.checkSession()
                }
            }
        }
    }

    private func stopForegroundCheckTimer() {
        foregroundCheckTask?.cancel()
        foregroundCheckTask = nil
    }
}

extension View {
    func handleAppLifecycle() -> some View {
        modifier(AppLifecycleHandler())
    }
}
