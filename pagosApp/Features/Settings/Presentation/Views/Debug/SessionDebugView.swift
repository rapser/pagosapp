//
//  SessionDebugView.swift
//  pagosApp
//
//  Debug view for testing session management and startup behavior.
//  Clean Architecture - Debug/Testing utility.
//

import SwiftUI

struct SessionDebugView: View {
    @Environment(SessionCoordinator.self) private var sessionCoordinator
    @Environment(AppDependencies.self) private var dependencies
    
    @State private var sessionInfo = "Loading..."
    @State private var refreshCount = 0
    
    private var sessionRepository: SessionRepositoryProtocol {
        dependencies.authDependencyContainer.makeSessionRepository()
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Current Session State") {
                    LabeledContent("Is Authenticated", value: sessionCoordinator.isAuthenticated ? "✅ Yes" : "❌ No")
                    LabeledContent("Is Session Active", value: sessionCoordinator.isSessionActive ? "✅ Yes" : "❌ No")
                    LabeledContent("Can Use Biometric", value: sessionCoordinator.canUseBiometrics ? "✅ Yes" : "❌ No")
                    LabeledContent("Refresh Count", value: "\(refreshCount)")
                }
                
                Section("Session Details") {
                    Text(sessionInfo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("Test Actions") {
                    Button("Refresh Session Info") {
                        refreshSessionInfo()
                        refreshCount += 1
                    }
                    
                    Button("Force Session Check", role: .destructive) {
                        Task {
                            sessionCoordinator.checkSession()
                            refreshSessionInfo()
                        }
                    }
                    
                    Button("Simulate App Restart") {
                        Task {
                            // End session temporarily to test startup behavior
                            await sessionRepository.endSession()
                            
                            // Wait a moment
                            try? await Task.sleep(for: .seconds(0.5))
                            
                            // Start session again to simulate restart
                            await sessionRepository.startSession()
                            refreshSessionInfo()
                        }
                    }
                    
                    Button("Clear All Session Data", role: .destructive) {
                        Task {
                            await sessionRepository.clearSession()
                            refreshSessionInfo()
                        }
                    }
                }
                
                Section("Instructions") {
                    Text("Use this view to test session startup behavior and avoid login screen flash.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text("• 'Simulate App Restart' tests the startup logic without actually closing the app")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text("• Watch for immediate state changes vs delayed background checks")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Session Debug")
            .task {
                refreshSessionInfo()
            }
        }
    }
    
    private func refreshSessionInfo() {
        Task { @MainActor in
            let hasActive = sessionRepository.hasActiveSession
            let lastActive = sessionRepository.lastActiveTimestamp
            let isExpired = sessionRepository.isSessionExpiredSync
            let remoteStatus = await dependencies.authDependencyContainer.makeGetAuthenticationStatusUseCase().execute()
            
            var info = "Local Active: \(hasActive)\n"
            info += "Local Expired: \(isExpired)\n"
            info += "Remote Valid: \(remoteStatus)\n"
            
            if let timestamp = lastActive {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .medium
                info += "Last Active: \(formatter.string(from: timestamp))\n"
                
                let elapsed = Date().timeIntervalSince(timestamp)
                info += "Elapsed: \(Int(elapsed))s\n"
            } else {
                info += "Last Active: None\n"
            }
            
            #if DEBUG
            info += "Debug Mode: Session timeout disabled"
            #else
            info += "Release Mode: 1 week timeout active"
            #endif
            
            sessionInfo = info
        }
    }
}

#Preview {
    let dependencies = AppDependencies.mock()
    let coordinator = SessionCoordinator(
        errorHandler: dependencies.errorHandler,
        settingsStore: dependencies.settingsStore,
        paymentSyncCoordinator: dependencies.paymentSyncCoordinator,
        reminderSyncCoordinator: dependencies.reminderSyncCoordinator,
        authDependencyContainer: dependencies.authDependencyContainer
    )
    
    SessionDebugView()
        .environment(dependencies)
        .environment(coordinator)
}