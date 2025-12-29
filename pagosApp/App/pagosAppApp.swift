//
//  pagosAppApp.swift
//  pagosApp
//
//  Created by miguel tomairo on 5/09/25.
//

import SwiftUI
import SwiftData
import Supabase
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "App")

/// Initialize Supabase client with configuration from Info.plist
/// Falls back to demo values if configuration is missing (for previews/tests)
private func createSupabaseClient() -> SupabaseClient {
    do {
        let url = try AppConfiguration.supabaseURL
        let key = try AppConfiguration.supabaseKey
        logger.info("✅ Supabase URL: \(url.absoluteString)")
        logger.info("✅ Supabase Key length: \(key.count) characters")
        logger.info("✅ Supabase client initialized successfully")
        return SupabaseClient(supabaseURL: url, supabaseKey: key)
    } catch {
        logger.error("❌ Failed to load Supabase configuration: \(error.localizedDescription)")
        logger.warning("⚠️ Using demo Supabase client for development")
        // Fallback for development/testing (e.g., SwiftUI Previews)
        guard let demoURL = URL(string: "https://demo.supabase.co") else {
            fatalError("Failed to create demo Supabase URL")
        }
        return SupabaseClient(
            supabaseURL: demoURL,
            supabaseKey: "demo_key"
        )
    }
}

let supabaseClient = createSupabaseClient()

@main
struct pagosAppApp: App {
    private let modelContainer: ModelContainer
    private let dependencies: AppDependencies

    init() {
        // Create ModelContainer first (needed for dependencies)
        self.modelContainer = Self.createModelContainer()

        // Create DI container with all dependencies
        self.dependencies = AppDependencies(
            modelContext: modelContainer.mainContext,
            supabaseClient: supabaseClient
        )

        // Request notification authorization at app launch (via DI)
        dependencies.notificationDataSource.requestAuthorization()

        logger.info("✅ App initialized with full DI Container")
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

    private static func createModelContainer() -> ModelContainer {
        let schema = Schema([PaymentEntity.self, UserProfile.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            logger.error("❌ Failed to create ModelContainer: \(error.localizedDescription)")
            
            // Try to recreate the database
            if let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let storeURL = appSupportURL.appendingPathComponent("default.store")
                try? FileManager.default.removeItem(at: storeURL)
                try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
                try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
                logger.info("Database files removed, attempting to recreate...")
            }

            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not initialize SwiftData container: \(error)")
            }
        }
    }

    private func cleanSwiftDataStore() {
        if let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let storeURL = appSupportURL.appendingPathComponent("default.store")
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
            logger.info("SwiftData store cleaned")
        }
    }
}
