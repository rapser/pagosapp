//
//  KeychainAuthDataSource.swift
//  pagosApp
//
//  Keychain implementation of local authentication data source
//  Clean Architecture - Data Layer
//

import Foundation
import Security
import OSLog

private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "KeychainAuthDataSource")

/// Keychain implementation of AuthLocalDataSource
final class KeychainAuthDataSource: AuthLocalDataSource {
    private let service = "com.rapser.pagosApp"
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let userIdKey = "userId"

    // MARK: - Token Management (Public API)

    func saveTokens(_ dto: KeychainCredentialsDTO) throws {
        logger.info("💾 Saving tokens to Keychain")

        do {
            try saveAccessToken(dto.accessToken)
            try saveRefreshToken(dto.refreshToken)
            try saveUserId(dto.userId)

            logger.info("✅ Tokens saved successfully")

        } catch {
            logger.error("❌ Failed to save tokens: \(error.localizedDescription)")
            throw AuthError.unknown("Failed to save tokens to Keychain")
        }
    }

    func getTokens() -> KeychainCredentialsDTO? {
        logger.debug("🔍 Retrieving tokens from Keychain")

        guard let accessToken = getAccessToken(),
              let refreshToken = getRefreshToken(),
              let userId = getUserId() else {
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
        clearAllTokens()
        logger.info("✅ Tokens cleared")
    }

    func hasStoredTokens() -> Bool {
        let hasTokens = getAccessToken() != nil &&
                       getRefreshToken() != nil &&
                       getUserId() != nil

        logger.debug("🔍 Has stored tokens: \(hasTokens)")
        return hasTokens
    }

    // MARK: - Private Keychain Operations

    private func upsertGenericPassword(account: String, data: Data) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        if updateStatus == errSecItemNotFound {
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                logger.error("Failed to add keychain item (\(account)): \(addStatus)")
                throw NSError(domain: "KeychainAuthDataSource", code: Int(addStatus), userInfo: nil)
            }
            return
        }

        logger.error("Failed to update keychain item (\(account)): \(updateStatus)")
        throw NSError(domain: "KeychainAuthDataSource", code: Int(updateStatus), userInfo: nil)
    }

    /// Save access token securely
    private func saveAccessToken(_ token: String) throws {
        let data = Data(token.utf8)
        try upsertGenericPassword(account: accessTokenKey, data: data)
    }

    /// Get access token
    private func getAccessToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accessTokenKey,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        return token
    }

    /// Save refresh token securely
    private func saveRefreshToken(_ token: String) throws {
        let data = Data(token.utf8)
        try upsertGenericPassword(account: refreshTokenKey, data: data)
    }

    /// Get refresh token
    private func getRefreshToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: refreshTokenKey,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        return token
    }

    /// Save user ID securely
    private func saveUserId(_ userId: String) throws {
        let data = Data(userId.utf8)
        try upsertGenericPassword(account: userIdKey, data: data)
    }

    /// Get user ID
    private func getUserId() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: userIdKey,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let userId = String(data: data, encoding: .utf8) else {
            return nil
        }

        return userId
    }

    /// Clear all tokens (access, refresh, userId)
    private func clearAllTokens() {
        let accounts = [accessTokenKey, refreshTokenKey, userIdKey]

        for account in accounts {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]

            SecItemDelete(query as CFDictionary)
        }

        logger.info("🗑️ All tokens cleared from Keychain")
    }
}
