//
//  AuthConfiguration.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

/// Configuration for authentication
struct AuthConfiguration {
    let provider: AuthProvider
    let supabaseURL: URL?
    let supabaseKey: String?
    let firebaseConfig: [String: Any]?
    let customAPIBaseURL: URL?
    
    /// Default configuration using Supabase
    static func supabase(url: URL, key: String) -> AuthConfiguration {
        return AuthConfiguration(
            provider: .supabase,
            supabaseURL: url,
            supabaseKey: key,
            firebaseConfig: nil,
            customAPIBaseURL: nil
        )
    }
    
    /// Firebase configuration (for future implementation)
    static func firebase(config: [String: Any]) -> AuthConfiguration {
        return AuthConfiguration(
            provider: .firebase,
            supabaseURL: nil,
            supabaseKey: nil,
            firebaseConfig: config,
            customAPIBaseURL: nil
        )
    }
    
    /// Custom API configuration (for future implementation)
    static func customAPI(baseURL: URL) -> AuthConfiguration {
        return AuthConfiguration(
            provider: .customAPI,
            supabaseURL: nil,
            supabaseKey: nil,
            firebaseConfig: nil,
            customAPIBaseURL: baseURL
        )
    }
}
