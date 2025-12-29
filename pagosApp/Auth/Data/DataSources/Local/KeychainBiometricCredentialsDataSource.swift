//
//  KeychainBiometricCredentialsDataSource.swift
//  pagosApp
//
//  Keychain implementation for biometric credentials storage
//  Clean Architecture - Data Layer
//

import Foundation
import Security
import LocalAuthentication
import OSLog

private let logger = Logger(subsystem: "com.rapser.pagosApp", category: "KeychainBiometricCredentialsDataSource")

/// Keychain implementation of BiometricCredentialsDataSource
final class KeychainBiometricCredentialsDataSource: BiometricCredentialsDataSource {
    private let service = "com.rapser.pagosApp"
    private let emailKey = "userEmail"
    private let passwordKey = "userPassword"
    private let hasLoggedInKey = "hasLoggedInWithCredentials"

    // MARK: - Credentials Management

    func saveCredentials(email: String, password: String) -> Bool {
        logger.info("💾 Saving biometric credentials")

        // Delete existing credentials first
        _ = deleteCredentials()

        guard let passwordData = password.data(using: .utf8) else {
            logger.error("Failed to encode password")
            return false
        }

        // Create access control for biometric authentication
        var accessControlError: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryCurrentSet, // Only accessible with current biometry
            &accessControlError
        ) else {
            logger.error("Failed to create access control")
            return false
        }

        // Email query
        let emailQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: emailKey,
            kSecValueData as String: email.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrSynchronizable as String: false // Never sync to iCloud
        ]

        // Password query with biometric protection
        let passwordQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: passwordKey,
            kSecValueData as String: passwordData,
            kSecAttrAccessControl as String: accessControl,
            kSecAttrSynchronizable as String: false // Never sync to iCloud
        ]

        // Save email
        let emailStatus = SecItemAdd(emailQuery as CFDictionary, nil)
        guard emailStatus == errSecSuccess else {
            logger.error("Failed to save email: \(emailStatus)")
            return false
        }

        // Save password
        let passwordStatus = SecItemAdd(passwordQuery as CFDictionary, nil)
        guard passwordStatus == errSecSuccess else {
            logger.error("Failed to save password: \(passwordStatus)")
            // Rollback email if password fails
            _ = deleteCredentials()
            return false
        }

        logger.info("✅ Biometric credentials saved successfully")
        return true
    }

    func retrieveCredentials(context: LAContext?) -> (email: String, password: String)? {
        logger.info("🔍 Retrieving biometric credentials")

        // Retrieve email
        guard let email = retrieveEmail(context: context) else {
            logger.warning("No email found in Keychain")
            return nil
        }

        // Retrieve password
        guard let password = retrievePassword(context: context) else {
            logger.warning("No password found in Keychain")
            return nil
        }

        logger.info("✅ Biometric credentials retrieved successfully")
        return (email, password)
    }

    func deleteCredentials() -> Bool {
        logger.info("🗑️ Deleting biometric credentials")

        // Delete email
        let emailQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: emailKey
        ]

        // Delete password
        let passwordQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: passwordKey
        ]

        let emailStatus = SecItemDelete(emailQuery as CFDictionary)
        let passwordStatus = SecItemDelete(passwordQuery as CFDictionary)

        // Consider success if items were deleted or didn't exist
        let emailSuccess = emailStatus == errSecSuccess || emailStatus == errSecItemNotFound
        let passwordSuccess = passwordStatus == errSecSuccess || passwordStatus == errSecItemNotFound

        if emailSuccess && passwordSuccess {
            logger.info("✅ Biometric credentials deleted successfully")
            return true
        } else {
            logger.error("Failed to delete credentials: email=\(emailStatus), password=\(passwordStatus)")
            return false
        }
    }

    func hasStoredCredentials() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: emailKey,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        let hasCredentials = status == errSecSuccess
        logger.debug("🔍 Has stored credentials: \(hasCredentials)")
        return hasCredentials
    }

    // MARK: - Private Helpers

    private func retrieveEmail(context: LAContext?) -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: emailKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        // Use provided context to avoid re-authentication
        if let context = context {
            query[kSecUseAuthenticationContext as String] = context
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let email = String(data: data, encoding: .utf8) else {
            return nil
        }

        return email
    }

    private func retrievePassword(context: LAContext?) -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: passwordKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        // Use provided context to avoid re-authentication
        if let context = context {
            query[kSecUseAuthenticationContext as String] = context
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let password = String(data: data, encoding: .utf8) else {
            return nil
        }

        return password
    }

    // MARK: - Login Flag Management

    func setHasLoggedIn(_ value: Bool) -> Bool {
        logger.info("💾 Setting hasLoggedIn flag: \(value)")
        let success = setBool(value, forKey: hasLoggedInKey)

        if success {
            logger.info("✅ HasLoggedIn flag saved successfully")
        } else {
            logger.error("❌ Failed to save hasLoggedIn flag")
        }

        return success
    }

    func getHasLoggedIn() -> Bool {
        let hasLoggedIn = getBool(forKey: hasLoggedInKey) ?? false
        logger.debug("🔍 HasLoggedIn: \(hasLoggedIn)")
        return hasLoggedIn
    }

    func deleteHasLoggedIn() -> Bool {
        logger.info("🗑️ Deleting hasLoggedIn flag")
        let success = deleteBool(forKey: hasLoggedInKey)

        if success {
            logger.info("✅ HasLoggedIn flag deleted successfully")
        } else {
            logger.error("❌ Failed to delete hasLoggedIn flag")
        }

        return success
    }

    // MARK: - Private Boolean Flag Storage

    /// Save a boolean flag to Keychain (without biometric protection)
    private func setBool(_ value: Bool, forKey key: String) -> Bool {
        let data = Data([value ? 1 : 0])

        // Delete existing value first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new value
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrSynchronizable as String: false
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Retrieve a boolean flag from Keychain
    private func getBool(forKey key: String) -> Bool? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let byte = data.first else {
            return nil
        }

        return byte == 1
    }

    /// Delete a boolean flag from Keychain
    @discardableResult
    private func deleteBool(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
