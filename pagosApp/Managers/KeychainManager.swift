//
//  KeychainManager.swift
//  pagosApp
//
//  Secure storage for user credentials using iOS Keychain
//

import Foundation
import Security
import OSLog
import LocalAuthentication

/// Manager for securely storing and retrieving user credentials in Keychain
class KeychainManager {
    
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "pagosApp", category: "KeychainManager")
    private static let service = "com.rapser.pagosApp"
    private static let emailKey = "userEmail"
    private static let passwordKey = "userPassword"
    private static let hasLoggedInKey = "hasLoggedInWithCredentials"
    
    // MARK: - Save Credentials
    
    /// Securely save user credentials to Keychain
    /// - Parameters:
    ///   - email: User's email
    ///   - password: User's password
    /// - Returns: True if saved successfully, false otherwise
    static func saveCredentials(email: String, password: String) -> Bool {
        logger.info("Attempting to save credentials to Keychain")
        
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
        
        logger.info("✅ Credentials saved successfully to Keychain")
        return true
    }
    
    // MARK: - Retrieve Credentials
    
    /// Retrieve user credentials from Keychain
    /// - Parameter context: Optional LAContext for biometric authentication (reuses existing authentication)
    /// - Returns: Tuple with email and password if found, nil otherwise
    static func retrieveCredentials(context: LAContext? = nil) -> (email: String, password: String)? {
        logger.info("Attempting to retrieve credentials from Keychain")
        
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
        
        logger.info("✅ Credentials retrieved successfully from Keychain")
        return (email, password)
    }
    
    private static func retrieveEmail(context: LAContext? = nil) -> String? {
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
    
    private static func retrievePassword(context: LAContext? = nil) -> String? {
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
    
    // MARK: - Delete Credentials
    
    /// Delete user credentials from Keychain
    /// - Returns: True if deleted successfully, false otherwise
    static func deleteCredentials() -> Bool {
        logger.info("Attempting to delete credentials from Keychain")
        
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
            logger.info("✅ Credentials deleted successfully from Keychain")
            return true
        } else {
            logger.error("Failed to delete credentials: email=\(emailStatus), password=\(passwordStatus)")
            return false
        }
    }
    
    // MARK: - Check Credentials Exist
    
    /// Check if credentials are stored in Keychain
    /// - Returns: True if credentials exist, false otherwise
    static func hasStoredCredentials() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: emailKey,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Boolean Flag Storage
    
    /// Save a boolean flag to Keychain (without biometric protection)
    /// - Parameters:
    ///   - value: The boolean value to save
    ///   - key: The key to store the value under
    /// - Returns: True if saved successfully, false otherwise
    static func setBool(_ value: Bool, forKey key: String) -> Bool {
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
    /// - Parameter key: The key to retrieve the value for
    /// - Returns: The boolean value if found, nil otherwise
    static func getBool(forKey key: String) -> Bool? {
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
    /// - Parameter key: The key to delete
    /// - Returns: True if deleted successfully, false otherwise
    @discardableResult
    static func deleteBool(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Convenience Methods for hasLoggedInWithCredentials
    
    /// Save the hasLoggedInWithCredentials flag
    static func setHasLoggedIn(_ value: Bool) -> Bool {
        return setBool(value, forKey: hasLoggedInKey)
    }
    
    /// Retrieve the hasLoggedInWithCredentials flag
    static func getHasLoggedIn() -> Bool {
        return getBool(forKey: hasLoggedInKey) ?? false
    }
    
    /// Delete the hasLoggedInWithCredentials flag
    @discardableResult
    static func deleteHasLoggedIn() -> Bool {
        return deleteBool(forKey: hasLoggedInKey)
    }
}
