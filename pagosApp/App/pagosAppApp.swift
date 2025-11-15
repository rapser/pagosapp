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
        let url = try ConfigurationManager.supabaseURL
        let key = try ConfigurationManager.supabaseKey
        logger.info("✅ Supabase client initialized successfully")
        return SupabaseClient(supabaseURL: url, supabaseKey: key)
    } catch {
        logger.error("❌ Failed to load Supabase configuration: \(error.localizedDescription)")
        logger.warning("⚠️ Using demo Supabase client for development")
        // Fallback for development/testing (e.g., SwiftUI Previews)
        return SupabaseClient(
            supabaseURL: URL(string: "https://demo.supabase.co")!,
            supabaseKey: "demo_key"
        )
    }
}

let supabaseClient = createSupabaseClient()

@main
struct pagosAppApp: App {
    private let supabaseAuthService = SupabaseAuthService(client: supabaseClient)
    private let authenticationManager: AuthenticationManager

    init() {
        authenticationManager = AuthenticationManager(authService: supabaseAuthService)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authenticationManager)
                .tint(Color("AppPrimary"))
        }
        .modelContainer(createModelContainer())
    }

    private func createModelContainer() -> ModelContainer {
        let schema = Schema([Payment.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        // Clean database on app start
//        cleanSwiftDataStore()

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            if let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let storeURL = appSupportURL.appendingPathComponent("default.store")
                try? FileManager.default.removeItem(at: storeURL)
                try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
                try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
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
