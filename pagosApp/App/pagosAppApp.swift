//
//  pagosAppApp.swift
//  pagosApp
//
//  Main app entry point
//  Orchestrates app initialization and dependency injection
//

import SwiftUI
import SwiftData

@main
struct pagosAppApp: App {
    private let modelContainer: ModelContainer
    private let dependencies: AppDependencies

    init() {
        // Initialize infrastructure components using factories
        self.modelContainer = ModelContainerFactory.create()

        let supabaseClient = SupabaseClientFactory.create()

        // Create dependency injection container
        self.dependencies = AppDependencies(
            modelContext: modelContainer.mainContext,
            supabaseClient: supabaseClient
        )

        // Request permissions at app launch
        dependencies.notificationDataSource.requestAuthorization()
        dependencies.calendarEventDataSource.requestAccess { _ in }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dependencies)
                .environment(dependencies.sessionCoordinator)
                .environment(dependencies.paymentSyncCoordinator)
                .environment(dependencies.settingsStore)
                .environment(dependencies.alertManager)
                .tint(Color("AppPrimary"))
        }
        .modelContainer(modelContainer)
    }

}
