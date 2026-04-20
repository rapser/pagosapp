import SwiftUI
import SwiftData

@MainActor
@Observable
final class AppBootstrapState {
    var modelContainer: ModelContainer?
    var dependencies: AppDependencies?
    var startupFailureMessage: String?
    var isBootstrapping = true
    private var didRequestPermissions = false

    func bootstrapIfNeeded() async {
        guard isBootstrapping else { return }

        let bootstrapLog = OSLogDomainLogWriter()
        let modelContainerResult = ModelContainerFactory.create(log: bootstrapLog)
        self.modelContainer = modelContainerResult.container
        self.startupFailureMessage = modelContainerResult.failureDescription

        guard let modelContainer else {
            isBootstrapping = false
            return
        }

        let supabaseClient = SupabaseClientFactory.create(log: bootstrapLog)
        let dependencies = AppDependencies(
            modelContext: modelContainer.mainContext,
            supabaseClient: supabaseClient
        )
        self.dependencies = dependencies

        if modelContainerResult.didFallbackToInMemory {
            dependencies.alertManager.show(
                title: Text(L10n.General.error),
                message: Text(L10n.Log.Db.modelContainerFailed(modelContainerResult.failureDescription ?? "")),
                buttons: [AlertButton(title: Text(L10n.General.ok), role: nil, action: { })]
            )
        }

        requestStartupPermissionsIfNeeded(using: dependencies)
        isBootstrapping = false
    }

    private func requestStartupPermissionsIfNeeded(using dependencies: AppDependencies) {
        guard !didRequestPermissions else { return }
        didRequestPermissions = true

        dependencies.notificationDataSource.requestAuthorization()
        dependencies.calendarEventDataSource.requestAccess { _ in }
    }
}

struct AppBootstrapView: View {
    @State private var bootstrapState = AppBootstrapState()

    var body: some View {
        Group {
            if bootstrapState.isBootstrapping {
                LoadingView(message: L10n.General.loading)
            } else if let dependencies = bootstrapState.dependencies,
                      let modelContainer = bootstrapState.modelContainer {
                ContentView()
                    .environment(dependencies)
                    .environment(dependencies.sessionCoordinator)
                    .environment(dependencies.paymentSyncCoordinator)
                    .environment(dependencies.reminderSyncCoordinator)
                    .environment(dependencies.appSyncManager)
                    .environment(dependencies.settingsStore)
                    .environment(dependencies.alertManager)
                    .modelContainer(modelContainer)
            } else {
                ErrorStateView(
                    title: L10n.General.error,
                    message: bootstrapState.startupFailureMessage,
                    onRetry: nil
                )
            }
        }
        .tint(Color("AppPrimary"))
        .task {
            await bootstrapState.bootstrapIfNeeded()
        }
    }
}
