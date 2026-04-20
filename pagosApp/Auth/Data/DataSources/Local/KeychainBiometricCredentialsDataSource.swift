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

/// Keychain implementation of BiometricCredentialsDataSource
final class KeychainBiometricCredentialsDataSource: BiometricCredentialsDataSource {
    private static let logCategory = "KeychainBiometricCredentialsDataSource"

    private let log: DomainLogWriter
    private let service = "com.rapser.pagosApp"

    init(log: DomainLogWriter) {
        self.log = log
    }
    private let emailKey = "userEmail"
    private let passwordKey = "userPassword"
    private let hasLoggedInKey = "hasLoggedInWithCredentials"

    // MARK: - Credentials Management

    func saveCredentials(email: String, password: String) -> Bool {
        log.info("💾 Saving biometric credentials", category: Self.logCategory)

        guard let passwordData = password.data(using: .utf8) else {
            log.error("Failed to encode password", category: Self.logCategory)
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
            log.error("Failed to create access control", category: Self.logCategory)
            return false
        }

        guard let emailData = email.data(using: .utf8) else {
            log.error("Failed to encode email", category: Self.logCategory)
            return false
        }

        do {
            try upsertGenericPassword(
                account: emailKey,
                data: emailData,
                accessControl: nil,
                synchronizable: false
            )

            do {
                try upsertGenericPassword(
                    account: passwordKey,
                    data: passwordData,
                    accessControl: accessControl,
                    synchronizable: false
                )
            } catch {
                log.error("Failed to save password: \(error.localizedDescription)", category: Self.logCategory)
                // Best-effort rollback to avoid leaving email without password
                _ = deleteCredentials()
                return false
            }
        } catch {
            log.error("Failed to save email: \(error.localizedDescription)", category: Self.logCategory)
            return false
        }

        log.info("✅ Biometric credentials saved successfully", category: Self.logCategory)
        return true
    }

    func retrieveCredentials(context: LAContext?) -> (email: String, password: String)? {
        log.info("🔍 Retrieving biometric credentials", category: Self.logCategory)

        // Retrieve email
        guard let email = retrieveEmail(context: context) else {
            log.warning("No email found in Keychain", category: Self.logCategory)
            return nil
        }

        // Retrieve password
        guard let password = retrievePassword(context: context) else {
            log.warning("No password found in Keychain", category: Self.logCategory)
            return nil
        }

        log.info("✅ Biometric credentials retrieved successfully", category: Self.logCategory)
        return (email, password)
    }

    func deleteCredentials() -> Bool {
        log.info("🗑️ Deleting biometric credentials", category: Self.logCategory)

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
            log.info("✅ Biometric credentials deleted successfully", category: Self.logCategory)
            return true
        } else {
            log.error("Failed to delete credentials: email=\(emailStatus), password=\(passwordStatus)", category: Self.logCategory)
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
        return hasCredentials
    }

    // MARK: - Private Helpers

    private func upsertGenericPassword(
        account: String,
        data: Data,
        accessControl: SecAccessControl?,
        synchronizable: Bool
    ) throws {
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
            query[kSecAttrSynchronizable as String] = synchronizable

            if let accessControl {
                query[kSecAttrAccessControl as String] = accessControl
            }

            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                log.error("Failed to add keychain item (\(account)): \(addStatus)", category: Self.logCategory)
                throw NSError(domain: "KeychainBiometricCredentialsDataSource", code: Int(addStatus), userInfo: nil)
            }
            return
        }

        log.error("Failed to update keychain item (\(account)): \(updateStatus)", category: Self.logCategory)
        throw NSError(domain: "KeychainBiometricCredentialsDataSource", code: Int(updateStatus), userInfo: nil)
    }

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
        log.info("💾 Setting hasLoggedIn flag: \(value)", category: Self.logCategory)
        let success = setBool(value, forKey: hasLoggedInKey)

        if success {
            log.info("✅ HasLoggedIn flag saved successfully", category: Self.logCategory)
        } else {
            log.error("❌ Failed to save hasLoggedIn flag", category: Self.logCategory)
        }

        return success
    }

    func getHasLoggedIn() -> Bool {
        let hasLoggedIn = getBool(forKey: hasLoggedInKey) ?? false
        log.debug("🔍 HasLoggedIn: \(hasLoggedIn)", category: Self.logCategory)
        return hasLoggedIn
    }

    func deleteHasLoggedIn() -> Bool {
        log.info("🗑️ Deleting hasLoggedIn flag", category: Self.logCategory)
        let success = deleteBool(forKey: hasLoggedInKey)

        if success {
            log.info("✅ HasLoggedIn flag deleted successfully", category: Self.logCategory)
        } else {
            log.error("❌ Failed to delete hasLoggedIn flag", category: Self.logCategory)
        }

        return success
    }

    // MARK: - Private Boolean Flag Storage

    /// Save a boolean flag to Keychain (without biometric protection)
    private func setBool(_ value: Bool, forKey key: String) -> Bool {
        let data = Data([value ? 1 : 0])

        do {
            try upsertGenericPassword(
                account: key,
                data: data,
                accessControl: nil,
                synchronizable: false
            )
            return true
        } catch {
            log.error("Failed to save boolean flag (\(key)): \(error.localizedDescription)", category: Self.logCategory)
            return false
        }
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
