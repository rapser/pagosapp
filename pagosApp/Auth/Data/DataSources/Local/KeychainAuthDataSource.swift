//
//  KeychainAuthDataSource.swift
//  pagosApp
//
//  Keychain implementation of local authentication data source
//  Clean Architecture - Data Layer
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "KeychainAuthDataSource")

/// Keychain implementation of AuthLocalDataSource
final class KeychainAuthDataSource: AuthLocalDataSource {
    private let keychainManager: KeychainManager.Type

    /// Initialize with KeychainManager type (for dependency injection/testing)
    init(keychainManager: KeychainManager.Type = KeychainManager.self) {
        self.keychainManager = keychainManager
    }

    // MARK: - Token Management

    func saveTokens(_ dto: KeychainCredentialsDTO) throws {
        logger.info("💾 Saving tokens to Keychain")

        do {
            try keychainManager.saveAccessToken(dto.accessToken)
            try keychainManager.saveRefreshToken(dto.refreshToken)
            try keychainManager.saveUserId(dto.userId)

            logger.info("✅ Tokens saved successfully")

        } catch {
            logger.error("❌ Failed to save tokens: \(error.localizedDescription)")
            throw AuthError.unknown("Failed to save tokens to Keychain")
        }
    }

    func getTokens() -> KeychainCredentialsDTO? {
        logger.debug("🔍 Retrieving tokens from Keychain")

        guard let accessToken = keychainManager.getAccessToken(),
              let refreshToken = keychainManager.getRefreshToken(),
              let userId = keychainManager.getUserId() else {
            logger.debug("⚠️ No tokens found in Keychain")
            return nil
        }

        logger.debug("✅ Tokens retrieved successfully")

        return KeychainCredentialsDTO(
            accessToken: accessToken,
            refreshToken: refreshToken,
            userId: userId
        )
    }

    func clearTokens() {
        logger.info("🗑️ Clearing tokens from Keychain")
        keychainManager.clearAllTokens()
        logger.info("✅ Tokens cleared")
    }

    func hasStoredTokens() -> Bool {
        let hasTokens = keychainManager.getAccessToken() != nil &&
                       keychainManager.getRefreshToken() != nil &&
                       keychainManager.getUserId() != nil

        logger.debug("🔍 Has stored tokens: \(hasTokens)")
        return hasTokens
    }
}
