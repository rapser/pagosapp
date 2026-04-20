//
//  KeychainAuthDataSource.swift
//  pagosApp
//
//  Keychain implementation of local authentication data source
//  Clean Architecture - Data Layer
//

import Foundation
import Security

/// Keychain implementation of AuthLocalDataSource
final class KeychainAuthDataSource: AuthLocalDataSource {
    private static let logCategory = "KeychainAuthDataSource"

    private let log: DomainLogWriter
    private let service = "com.rapser.pagosApp"

    init(log: DomainLogWriter) {
        self.log = log
    }
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let userIdKey = "userId"

    // MARK: - Token Management (Public API)

    func saveTokens(_ dto: KeychainCredentialsDTO) throws {
        log.info("💾 Saving tokens to Keychain", category: Self.logCategory)

        do {
            try saveAccessToken(dto.accessToken)
            try saveRefreshToken(dto.refreshToken)
            try saveUserId(dto.userId)

            log.info("✅ Tokens saved successfully", category: Self.logCategory)

        } catch {
            log.error("❌ Failed to save tokens: \(error.localizedDescription)", category: Self.logCategory)
            throw AuthError.unknown("Failed to save tokens to Keychain")
        }
    }

    func getTokens() -> KeychainCredentialsDTO? {
        log.debug("🔍 Retrieving tokens from Keychain", category: Self.logCategory)

        guard let accessToken = getAccessToken(),
              let refreshToken = getRefreshToken(),
              let userId = getUserId() else {
            log.debug("⚠️ No tokens found in Keychain", category: Self.logCategory)
            return nil
        }

        log.debug("✅ Tokens retrieved successfully", category: Self.logCategory)

        return KeychainCredentialsDTO(
            accessToken: accessToken,
            refreshToken: refreshToken,
            userId: userId
        )
    }

    func clearTokens() {
        log.info("🗑️ Clearing tokens from Keychain", category: Self.logCategory)
        clearAllTokens()
        log.info("✅ Tokens cleared", category: Self.logCategory)
    }

    func hasStoredTokens() -> Bool {
        let hasTokens = getAccessToken() != nil &&
                       getRefreshToken() != nil &&
                       getUserId() != nil

        log.debug("🔍 Has stored tokens: \(hasTokens)", category: Self.logCategory)
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
                log.error("Failed to add keychain item (\(account)): \(addStatus)", category: Self.logCategory)
                throw NSError(domain: "KeychainAuthDataSource", code: Int(addStatus), userInfo: nil)
            }
            return
        }

        log.error("Failed to update keychain item (\(account)): \(updateStatus)", category: Self.logCategory)
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

        log.info("🗑️ All tokens cleared from Keychain", category: Self.logCategory)
    }
}
