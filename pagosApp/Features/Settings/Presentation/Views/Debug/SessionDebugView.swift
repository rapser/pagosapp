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

    @State private var sessionInfo = ""
    @State private var refreshCount = 0

    private var sessionRepository: SessionRepositoryProtocol {
        dependencies.authDependencyContainer.makeSessionRepository()
    }

    var body: some View {
        NavigationView {
            Form {
                Section(L10n.Debug.Session.sectionCurrent) {
                    LabeledContent(L10n.Debug.Session.isAuthenticated, value: sessionCoordinator.isAuthenticated ? L10n.Debug.Session.checkYes : L10n.Debug.Session.checkNo)
                    LabeledContent(L10n.Debug.Session.isSessionActive, value: sessionCoordinator.isSessionActive ? L10n.Debug.Session.checkYes : L10n.Debug.Session.checkNo)
                    LabeledContent(L10n.Debug.Session.canUseBiometric, value: sessionCoordinator.canUseBiometrics ? L10n.Debug.Session.checkYes : L10n.Debug.Session.checkNo)
                    LabeledContent(L10n.Debug.Session.refreshCount, value: "\(refreshCount)")
                }

                Section(L10n.Debug.Session.sectionDetails) {
                    Text(sessionInfo.isEmpty ? L10n.General.loading : sessionInfo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section(L10n.Debug.Session.sectionActions) {
                    Button(L10n.Debug.Session.refreshInfo) {
                        refreshSessionInfo()
                        refreshCount += 1
                    }

                    Button(L10n.Debug.Session.forceCheck, role: .destructive) {
                        Task {
                            sessionCoordinator.checkSession()
                            refreshSessionInfo()
                        }
                    }

                    Button(L10n.Debug.Session.simulateRestart) {
                        Task {
                            await sessionRepository.endSession()

                            try? await Task.sleep(for: .seconds(0.5))

                            await sessionRepository.startSession()
                            refreshSessionInfo()
                        }
                    }

                    Button(L10n.Debug.Session.clearData, role: .destructive) {
                        Task {
                            await sessionRepository.clearSession()
                            refreshSessionInfo()
                        }
                    }
                }

                Section(L10n.Debug.Session.sectionInstructions) {
                    Text(L10n.Debug.Session.instructionIntro)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(L10n.Debug.Session.instructionRestart)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(L10n.Debug.Session.instructionWatch)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(L10n.Debug.Session.navTitle)
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

            let yes = L10n.General.yes
            let no = L10n.General.no

            var info = L10n.Debug.Session.infoLocalActive(hasActive ? yes : no) + "\n"
            info += L10n.Debug.Session.infoLocalExpired(isExpired ? yes : no) + "\n"
            info += L10n.Debug.Session.infoRemoteValid(String(describing: remoteStatus)) + "\n"

            if let timestamp = lastActive {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .medium
                formatter.locale = .current
                info += L10n.Debug.Session.infoLastActive(formatter.string(from: timestamp)) + "\n"

                let elapsed = Date().timeIntervalSince(timestamp)
                info += L10n.Debug.Session.infoElapsedSeconds(Int(elapsed)) + "\n"
            } else {
                info += L10n.Debug.Session.infoLastActiveNone + "\n"
            }

            #if DEBUG
            info += L10n.Debug.Session.infoDebugMode
            #else
            info += L10n.Debug.Session.infoReleaseMode
            #endif

            sessionInfo = info
        }
    }
}

#Preview {
    let dependencies = AppDependencies.mock()
    let coordinateSync = CoordinateSyncUseCase(
        paymentSyncCoordinator: dependencies.paymentSyncCoordinator,
        reminderSyncCoordinator: dependencies.reminderSyncCoordinator,
        log: dependencies.domainLog
    )
    let coordinator = SessionCoordinator(
        errorHandler: dependencies.errorHandler,
        settingsStore: dependencies.settingsStore,
        paymentSyncCoordinator: dependencies.paymentSyncCoordinator,
        reminderSyncCoordinator: dependencies.reminderSyncCoordinator,
        coordinateSyncUseCase: coordinateSync,
        authDependencyContainer: dependencies.authDependencyContainer
    )

    SessionDebugView()
        .environment(dependencies)
        .environment(coordinator)
}
