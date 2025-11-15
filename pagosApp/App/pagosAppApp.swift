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
        .modelContainer(for: Payment.self)
    }
}
