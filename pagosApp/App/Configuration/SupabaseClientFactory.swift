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
    private static let requestTimeout: TimeInterval = 30
    private static let resourceTimeout: TimeInterval = 60

    /// Creates a configured Supabase client instance
    /// Falls back to demo client for development/previews if configuration is missing
    static func create() -> SupabaseClient {
        do {
            let url = try AppConfiguration.supabaseURL
            let key = try AppConfiguration.supabaseKey

            let session = makePinnedSessionIfPossible()
            let options = SupabaseClientOptions(global: .init(session: session))
            return SupabaseClient(supabaseURL: url, supabaseKey: key, options: options)
        } catch {
            logger.error("❌ Failed to load Supabase configuration: \(error.localizedDescription)")
            logger.warning("⚠️ Using demo Supabase client for development")

            return createDemoClient()
        }
    }

    private static func makePinnedSessionIfPossible() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = requestTimeout
        configuration.timeoutIntervalForResource = resourceTimeout

        let certificateURLs = Bundle.main.urls(forResourcesWithExtension: "cer", subdirectory: nil) ?? []
        let pinned = certificateURLs.compactMap { try? Data(contentsOf: $0) }

        guard !pinned.isEmpty else {
            return URLSession(configuration: configuration)
        }

        let delegate = SSLPinningURLSessionDelegate(pinnedCertificateData: pinned)
        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }

    /// Creates a demo client for development/testing (SwiftUI Previews, tests)
    private static func createDemoClient() -> SupabaseClient {
        let demoURL: URL = {
            guard let url = URL(string: "https://demo.supabase.co") else {
                preconditionFailure("SupabaseClientFactory: invalid demo URL literal")
            }
            return url
        }()
        return SupabaseClient(
            supabaseURL: demoURL,
            supabaseKey: "demo_key"
        )
    }
}
