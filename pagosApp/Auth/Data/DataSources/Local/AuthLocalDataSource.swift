//
//  AuthLocalDataSource.swift
//  pagosApp
//
//  Protocol for local authentication data source
//  Clean Architecture - Data Layer
//

import Foundation

/// Protocol defining local authentication data operations
protocol AuthLocalDataSource {
    // MARK: - Token Management

    /// Save authentication tokens
    func saveTokens(_ dto: KeychainCredentialsDTO) throws

    /// Get stored tokens
    func getTokens() -> KeychainCredentialsDTO?

    /// Clear all tokens
    func clearTokens()

    /// Check if tokens exist
    func hasStoredTokens() -> Bool
}
