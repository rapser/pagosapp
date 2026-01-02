//
//  SupabaseClientFactory.swift
//  pagosApp
//
//  Factory for creating Supabase client instances
//  Infrastructure Layer - Configuration
//

import Foundation
import Supabase
import OSLog

/// Factory responsible for creating and configuring Supabase client instances
enum SupabaseClientFactory {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "SupabaseFactory")

    /// Creates a configured Supabase client instance
    /// Falls back to demo client for development/previews if configuration is missing
    static func create() -> SupabaseClient {
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

            return createDemoClient()
        }
    }

    /// Creates a demo client for development/testing (SwiftUI Previews, tests)
    private static func createDemoClient() -> SupabaseClient {
        guard let demoURL = URL(string: "https://demo.supabase.co") else {
            fatalError("Failed to create demo Supabase URL")
        }

        return SupabaseClient(
            supabaseURL: demoURL,
            supabaseKey: "demo_key"
        )
    }
}
